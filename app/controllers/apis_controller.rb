class ApisController < ApplicationController
	def api_call
		redis = UtilsService.redis
		api_id = params[:id]
		slot_name = params[:slot]
		path = params[:path]

		slot_name = "master" if slot_name.nil?

		# Get the api
		api = Api.find_by(id: api_id)
		ValidationService.raise_validation_errors(ValidationService.validate_api_existence(api))

		# Get the api slot
		slot = api.api_slots.find_by(name: slot_name)
		ValidationService.raise_validation_errors(ValidationService.validate_api_slot_existence(slot))

		# Find the appropriate api endpoint
		api_endpoint = ApiEndpoint.find_by(api_slot: slot, method: request.method, path: path)

		url_params = Hash.new
		url_query_params = Hash.new

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
			url_query_params[key] = value
		end

		cache_response = false

		if api_endpoint.caching && ENV["USE_API_ENDPOINT_REQUEST_CACHING"] == "true" && request.headers["Authorization"].nil? && request.method.downcase == "get"
			cache_params = url_query_params.sort.to_h
			cache_key = "api_endpoint_request:#{path}"

			cache_params.each do |key, value|
				cache_key += ";#{key}:#{value}"
			end

			cache = redis.get(cache_key)

			if !cache.nil?
				# Render the cached response
				render json: cache, status: 200
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
				api_slot: slot,
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
				api_slot: slot,
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
			redis.set(cache_key, result[:data].to_json)
			redis.expire(cache_key, 1.day.to_i)
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
		slot_name = params[:slot]

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		schema = body["schema"]

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

		# Get the api slot
		api_slot = api.api_slots.find_by(name: slot_name)
		ValidationService.raise_validation_errors(ValidationService.validate_api_slot_existence(api_slot))

		if !schema.nil?
			# TODO: Validate schema param

			# Read the schema and generate all required api endpoints
			# Go through each class
			schema.each do |class_name, class_data|
				class_name_snake = snake_case(class_name)
				class_name_snake_plural = name_plural(class_name_snake)
				next if class_data["endpoints"].nil?

				endpoints = class_data["endpoints"]
				properties = class_data["properties"]
				getters = ["url_getter"]

				# Try to find the table of the class
				table = api.app.tables.find_by(name: class_name)
				next if table.nil?

				if endpoints.include?("retrieve")
					# Generate the retrieve endpoint
					code = %{
						#{get_functions(api.app)}

						(# Get the params)
						(var uuid (get_param "uuid"))
						(var fields_str (get_param "fields"))

						(if (is_nil fields_str) (
							(var fields (hash (uuid (hash))))
						) else (
							(# Process the fields string)
							(var fields (func process_fields (fields_str)))
						))

						(# Get the access token)
						(var access_token (get_header "Authorization"))

						(# Get the session)
						(if (!(is_nil access_token)) (var session (func get_session (access_token))))

						(# Get the object)
						(var obj (func get_table_object (uuid)))

						(if (is_nil obj) (
							(# Object does not exist)
							(func render_validation_errors (
								(list (hash
									(error "#{class_name_snake}_does_not_exist")
									(status 404)
								))
							))
						))

						(def generate_result (key value obj schema class_name) (
							(var schema_class schema[class_name])
							(if (is_nil schema_class) (
								(var schema_class (hash))
							))

							(var schema_properties schema_class["properties"])
							(if (is_nil schema_properties) (
								(var schema_properties (hash))
							))

							(var schema_property schema_properties[key])
							(if (is_nil schema_property) (
								(var schema_property (hash))
							))

							(var getter schema_property["getter"])

							(if (value.keys.length == 0) (
								#{
									result = ""

									getters.each do |getter|
										result += %{
											(if (getter == "#{getter}") (
												(return (func #{getter} (obj (get_params))))
											))
										}
									end

									result
								}

								(return obj.properties[key])
							) else (
								(var relationship schema_property["relationship"])

								(if (relationship == "multiple") (
									(var items (list))
									(var uuids_string obj.properties[key])
									(if (is_nil uuids_string) (return items))

									(var uuids (uuids_string.split ","))

									(for uuid in uuids (
										(var item (hash))
										(var new_obj (func get_table_object (uuid)))

										(for subkey in value.keys (
											(var val
												(func generate_result (
													subkey
													value[subkey]
													new_obj
													schema
													schema_property["type"]
												))
											)

											(var item[subkey] val)
										))

										(items.push item)
									))

									(return items)
								) else (
									(var item (hash))
									(var uuid obj.properties[key])
									(var new_obj (func get_table_object (uuid)))

									(if (is_nil new_obj) (
										(return nil)
									))

									(for subkey in value.keys (
										(var val
											(func generate_result (
												subkey
												value[subkey]
												new_obj
												schema
												schema_property["type"]
											))
										)

										(var item[subkey] val)
									))

									(return item)
								))
							))
						))

						(# Render the result)
						(var result (hash))

						(for key in fields.keys (
							(var value (func generate_result (key fields[key] obj
								(hash
									(Publisher (hash
										(properties (hash
											(authors (hash
												(type "Author")
												(relationship "multiple")
											))
											(logo (hash
												(type "PublisherLogo")
											))
										))
									))
									(PublisherLogo (hash
										(properties (hash
											(url (hash
												(type "String")
												(getter "url_getter")
											))
										))
									))
									(Author (hash
										(properties (hash
											(first_name (hash
												(type "String")
											))
											(last_name (hash
												(type "String")
											))
											(series (hash
												(relationship "multiple")
											))
										))
									))
									(StoreBookSeries (hash
										(properties (hash
											(name (hash
												(type "String")
											))
										))
									))
								)
								"Publisher"
							)))
							(var result[key] value)
						))

						(render_json result 200)
					}

					# Save the endpoint
					path = "#{class_name_snake_plural}/:uuid"
					api_endpoint = api_slot.api_endpoints.find_by(path: path, method: "GET")

					if api_endpoint.nil?
						ApiEndpoint.create(api_slot: api_slot, path: path, method: "GET", commands: code)
					else
						api_endpoint.commands = code
						api_endpoint.save
					end
				end
			end
		end

		# Compile each ApiEndpoint and create or update the CompiledApiEndpoints with the compiled code
		compiler = DavExpressionCompiler.new

		api_slot.api_endpoints.each do |endpoint|
			code = compiler.compile({
				api_slot: api_slot,
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

	private
	def snake_case(string)
		string.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
	end

	def name_plural(string)
		return "#{string[0..-2]}ies" if string[-1] == "y"
		return "#{string}s" if string[-1] != "s"
		return string
	end

	def get_functions(app)
		return %{
			(def process_fields (input) (
				(var result (hash))
				(var depth 0)
				(var current_key "")
				(var current_value "")

				(for char in input.chars (
					(if (char == " ") (continue))

					(if ((char == ",") && (depth == 0)) (
						(if (current_key.size == 0) (continue))
						(var result[current_key] (hash))
						(var current_key "")
					) elseif (char == "[") (
						(if (depth > 0) (
							(var current_value (current_value + char))
						))

						(var depth (depth + 1))
					) elseif (char == "]") (
						(if (depth > 1) (
							(var current_value (current_value + char))
						))

						(var depth (depth - 1))

						(if (depth == 0) (
							(var result[current_key] (func process_fields (current_value)))
							(var current_key "")
							(var current_value "")
						))
					) elseif (depth == 0) (
						(var current_key (current_key + char))
					) else (
						(var current_value (current_value + char))
					))
				))

				(if (current_key.size > 0) (
					(var result[current_key] (hash))
				))

				(return result)
			))

			(def get_session (token) (
				(# params: token: string)
				(catch (
					(var session (Session.get token))
				) (
					(var error errors#0)

					(if (error.code == 0) (
						(# Session does not exist)
						(var error_code 3501)
						(var status_code 404)
					) elseif (error.code == 1) (
						(# Can't use old access token)
						(var error_code 3100)
						(var status_code 403)
					) else (
						(# Session needs to be renewed)
						(var error_code 3101)
						(var status_code 403)
					))

					(func render_validation_errors ((list (hash (error (get_error error_code)) (status status_code)))))
				))

				(# Check if the session belongs to the app)
				(if (session.app_id != #{app.id}) (
					(# Action not allowed)
					(func render_validation_errors ((list (hash (error (get_error 1002)) (status 403)))))
				))

				(return session)
			))

			(def get_table_object (uuid user_id) (
				(# params: uuid: string, user_id: int)
				(if (is_nil uuid) (return nil))

				(catch (
					(var obj (TableObject.get uuid))
				) (
					(# Access not allowed)
					(func render_validation_errors ((list (hash (error (get_error 1002)) (status 403)))))
				))

				(if (is_nil obj) (
					(return nil)
				) else (
					(# Check if the table object belongs to the user and to the table)
					(if ((!(is_nil user_id)) and (obj.user_id != user_id)) (
						(# Action not allowed)
						(func render_validation_errors ((list (hash (error (get_error 1002)) (status 403)))))
					))

					(return obj)
				))
			))

			(def render_errors (errors status) (
				(# params: errors: list, status: int)
				(render_json (hash (errors errors)) status)
			))

			(def render_validation_errors (validations status) (
				(# params: validations: list<hash: error<hash: {code: string, message: string}>, status: number>)
				(# Save the errors in a separate list)
				(var errors (list))

				(for validation in validations (
					(errors.push validation.error)
				))

				(if (errors.length > 0) (
					(# Render the errors with the status of the first validation)
					(func render_errors (errors validations#0.status))
				))
			))
		}
	end
end