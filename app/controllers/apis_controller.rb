class ApisController < ApplicationController
	def api_call
		api_id = params[:id]
		slot_name = params[:slot]
		path = params[:path]

		slot_name = "master" if slot_name == "call"

		# Get the api
		api = Api.find_by(id: api_id)
		ValidationService.raise_validation_errors(ValidationService.validate_api_existence(api))

		# Get the api slot
		slot = api.api_slots.find_by(name: slot_name)
		ValidationService.raise_validation_errors(ValidationService.validate_api_slot_existence(slot))

		# Find the appropriate api endpoint
		api_endpoint = ApiEndpoint.find_by(api_slot: slot, method: request.method, path: path)
		url_params = Hash.new

		if api_endpoint.nil?
			# Try to find the appropriate endpoint with a variable in the url
			ApiEndpoint.where(api_slot: slot, method: request.method).each do |endpoint|
				path_parts = endpoint.path.split('/')
				url_parts = path.split('/')
				next if path_parts.count != url_parts.count

				url_vars = Hash.new
				cancelled = false
				i = -1

				path_parts.each do |part|
					i += 1

					if url_parts[i] == part
						next
					elsif part[0] == ':'
						url_vars[part[1..part.size]] = url_parts[i]
						next
					end

					cancelled = true
					break
				end

				if !cancelled
					api_endpoint = endpoint
					url_vars.each do |key, value|
						url_params[key] = value
					end

					break
				end
			end
		end

		ValidationService.raise_validation_errors(ValidationService.validate_api_endpoint_existence(api_endpoint))

		# Get the url params
		request.query_parameters.each do |key, value|
			url_params[key] = value
		end

		cache_response = false

		if api_endpoint.caching && Rails.env.production? && request.headers["Authorization"].nil? && request.method.downcase == "get"
			# Try to find a cache of the endpoint with this combination of params
			cache = nil
			cache_params = url_params.sort.to_h

			api_endpoint.api_endpoint_request_caches.each do |request_cache|
				request_cache_params = request_cache.api_endpoint_request_cache_params
				next if cache_params.size != request_cache_params.size

				# Convert the params to hash
				request_cache_params_hash = Hash.new
				request_cache_params.each { |param| request_cache_params_hash[param.name] = param.value }

				next if request_cache_params_hash != cache_params
				cache = request_cache
				break
			end

			if !cache.nil?
				# Render the cached response
				render json: cache.response, status: 200
				return
			else
				cache_response = true
			end
		end

		if ENV["USE_COMPILED_API_ENDPOINTS"] == "true" && !Rails.env.test?
			# Get the compiled endpoint
			compiled_api_endpoint = api_endpoint.compiled_api_endpoint
			ValidationService.raise_validation_errors(ValidationService.validate_compiled_api_endpoint_existence(compiled_api_endpoint))

			# Get the headers
			headers = Hash.new
			headers["Authorization"] = request.headers["Authorization"]
			headers["Content-Type"] = request.headers["Content-Type"]
			headers["Content-Disposition"] = request.headers["Content-Disposition"]

			compiler = DavExpressionCompiler.new
			result = compiler.run(
				code: compiled_api_endpoint.code,
				api: api,
				request: {
					headers: headers,
					params: url_params,
					body: request.body
				}
			)
		else
			vars = Hash.new

			# Get the environment variables
			vars["env"] = Hash.new
			slot.api_env_vars.each do |env_var|
				vars["env"][env_var.name] = UtilsService.convert_env_value(env_var.class_name, env_var.value)
			end

			# Get the headers
			headers = Hash.new
			headers["Authorization"] = request.headers["Authorization"]
			headers["Content-Type"] = request.headers["Content-Type"]
			headers["Content-Disposition"] = request.headers["Content-Disposition"]

			runner = DavExpressionRunner.new
			result = runner.run({
				api: api,
				vars: vars,
				commands: api_endpoint.commands,
				request: {
					headers: headers,
					params: url_params,
					body: request.body
				}
			})
		end

		if cache_response && result[:status] == 200
			# Save the response in the cache
			cache = ApiEndpointRequestCache.new(api_endpoint: api_endpoint, response: result[:data].to_json)

			if cache.save
				# Create the cache params
				cache_params.each do |var|
					# var = ["key", "value"]
					param = ApiEndpointRequestCacheParam.new(api_endpoint_request_cache: cache, name: var[0], value: var[1])
					param.save
				end
			end
		end

		# Send the result
		if result[:file]
			# Send the file
			result[:headers].each { |key, value| response.set_header(key, value) }
			send_data(result[:data], type: result[:type], filename: result[:filename], status: result[:status])
		else
			# Send the json
			render json: result[:data], status: result[:status]
		end
	rescue RuntimeError => e
		render_errors(e)
	end

	def create_api
		access_token = get_auth
		
		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		app_id = body["app_id"]
		name = body["name"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_app_id_presence(app_id),
			ValidationService.validate_name_presence(name)
		])

		# Validate the types of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_app_id_type(app_id),
			ValidationService.validate_name_type(name)
		])

		# Validate the name
		ValidationService.raise_validation_errors(ValidationService.validate_name_length(name))

		# Get the app
		app = App.find_by(id: app_id)
		ValidationService.raise_validation_errors(ValidationService.validate_app_existence(app))

		# Make sure the user is the dev of the app
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(app, session.user.dev))

		# Create the api
		api = Api.new(
			app: app,
			name: name
		)
		ValidationService.raise_unexpected_error(!api.save)

		result = {
			id: api.id,
			app_id: app.id,
			name: api.name,
			endpoints: Array.new,
			functions: Array.new,
			errors: Array.new
		}
		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end

	def compile_api
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Get the api
		api = Api.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_api_existence(api))

		# Check if the api belongs to an app of the dev of the user
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(api.app, dev))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		slot = body["slot"]

		# Validate missing fields
		ValidationService.raise_validation_errors(ValidationService.validate_slot_presence(slot))

		# Validate the types of the fields
		ValidationService.raise_validation_errors(ValidationService.validate_slot_type(slot))

		# Get the api slot
		api_slot = ApiSlot.find_by(api: api, name: slot)
		ValidationService.raise_validation_errors(ValidationService.validate_api_slot_existence(api_slotslot))

		# Compile each ApiEndpoint and create or update the CompiledApiEndpoints with the compiled code
		compiler = DavExpressionCompiler.new

		api_slot.api_endpoints.each do |endpoint|
			code = compiler.compile({
				api: api,
				commands: endpoint.commands
			})

			compiled_endpoint = endpoint.compiled_api_endpoint

			if compiled_endpoint.nil?
				# Create the compiled endpoint
				compiled_endpoint = CompiledApiEndpoint.new(api_endpoint: endpoint)
			end

			compiled_endpoint.code = code
			ValidationService.raise_unexpected_error(!compiled_endpoint.save)
		end

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end
end