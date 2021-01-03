class ApisController < ApplicationController
	def api_call
		api_id = params[:id]
		path = params[:path]

		# Get the api
		api = Api.find_by(id: api_id)
		ValidationService.raise_validation_error(ValidationService.validate_api_existence(api))

		# Find the appropriate api endpoint
		api_endpoint = ApiEndpoint.find_by(api: api, method: request.method, path: path)
		vars = Hash.new

		if api_endpoint.nil?
			# Try to find the appropriate endpoint with a variable in the url
			ApiEndpoint.where(api: api, method: request.method).each do |endpoint|
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
						vars[key] = value
					end

					break
				end
			end
		end

		ValidationService.raise_validation_error(ValidationService.validate_api_endpoint_existence(api_endpoint))

		# Get the url params
		request.query_parameters.each do |key, value|
			vars[key.to_s] = value
		end

		cache_response = false

		if api_endpoint.caching && Rails.env.production? && request.headers["Authorization"].nil? && request.method.downcase == "get"
			# Try to find a cache of the endpoint with this combination of params
			cache = nil
			cache_params = vars.sort.to_h

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

		# Get the environment variables
		vars["env"] = Hash.new
		api.api_env_vars.each do |env_var|
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
				body: request.body
			}
		})

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
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end