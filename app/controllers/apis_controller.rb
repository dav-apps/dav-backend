class ApisController < ApplicationController
	ALLOWED_TYPES = ["String", "String[]", "Boolean", "Integer", "Float", nil]

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
		api_docu = ""

		if !schema.nil?
			# Validate schema param
			ValidationService.raise_validation_errors(ValidationService.validate_schema_type(schema))

			# Read the schema and generate all required api endpoints
			# Go through each class
			schema.each do |class_name, class_data|
				class_name_snake = snake_case(class_name)
				class_name_snake_space = class_name_snake.gsub("_", " ")
				class_name_snake_plural = name_plural(class_name_snake)
				class_name_snake_space_plural = name_plural(class_name_snake_space)
				next if class_data["endpoints"].nil?

				endpoints = class_data["endpoints"]
				properties = class_data["properties"]
				schema_functions = get_schema_class_functions(schema, class_name)
				getters = schema_functions[:getters]

				# Try to find the table of the class
				table = api.app.tables.find_by(name: class_name)
				next if table.nil?

				if endpoints.include?("create")
					# Generate the create endpoint
					endpoint = endpoints["create"]

					code = %{
						#{get_functions(schema, api.app, getters)}

						#{generate_state_dx_code(endpoint)}

						(# Get the params)
						(var fields_str (get_param "fields"))

						(if (is_nil fields_str) (
							(var fields (hash (uuid (hash))))
						) else (
							(# Process the fields string)
							(var fields (func process_fields (fields_str)))
						))

						(var json (parse_json (get_body)))
						(var body_params (hash))

						#{generate_body_params_dx_code(properties)}

						(# Get the access token)
						(var access_token (get_header "Authorization"))

						(if (is_nil access_token) (
							(func render_validation_errors (
								(list (hash
									(error "authorization_header_missing")
									(status 401)
								))
							))
						))

						(# Make sure content type is json)
						(func validate_content_type_json ((get_header "Content-Type")))

						(# Get the session)
						(var session (func get_session (access_token)))

						(# Validate missing fields)
						#{generate_missing_field_validations_dx_code(properties)}

						(# Validate field types)
						#{generate_field_type_validations_dx_code(properties)}

						(# Validate too short and too long fields)
						#{generate_field_length_validations_dx_code(properties)}

						(# Validate validity of fields)
						#{generate_field_validity_validations_dx_code(properties)}

						(# Create the object)
						(var props (hash))

						(for key in body_params.keys (
							(var props[key] body_params[key])
						))

						(var obj (func create_table_object (
							session.user_id
							\"#{class_name}\"
							props
						)))

						(# Render the result)
						(var result (hash))

						(for key in fields.keys (
							(var value (func generate_result (
								key
								fields[key]
								obj
								schema
								\"#{class_name}\"
							)))

							(var result[key] value)
						))

						(render_json result 201)
					}

					# Save the endpoint
					api_endpoint = api_slot.api_endpoints.find_by(
						path: class_name_snake_plural,
						method: "POST"
					)

					if api_endpoint.nil?
						ApiEndpoint.create(
							api_slot: api_slot,
							path: class_name_snake_plural,
							method: "POST",
							commands: code
						)
					else
						api_endpoint.commands = code
						api_endpoint.save
					end
				end

				if endpoints.include?("retrieve")
					# Generate the retrieve endpoint
					code = %{
						#{get_functions(schema, api.app, getters)}

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

						(# Render the result)
						(var result (hash))

						(for key in fields.keys (
							(var value (func generate_result (
								key
								fields[key]
								obj
								schema
								\"#{class_name}\"
							)))

							(var result[key] value)
						))

						(render_json result 200)
					}

					# Save the endpoint
					path = "#{class_name_snake_plural}/:uuid"
					api_endpoint = api_slot.api_endpoints.find_by(
						path: path,
						method: "GET"
					)

					if api_endpoint.nil?
						ApiEndpoint.create(
							api_slot: api_slot,
							path: path,
							method: "GET",
							commands: code
						)
					else
						api_endpoint.commands = code
						api_endpoint.save
					end
				end

				if endpoints.include?("list")
					# Generate the list endpoint
					code = %{
						#{get_functions(schema, api.app, getters)}

						(# Get the params)
						(var uuid (get_param "uuid"))
						(var fields_str (get_param "fields"))

						(if (is_nil fields_str) (
							(var fields (hash (uuid (hash))))
						) else (
							(# Process the fields string)
							(var fields (func process_fields (fields_str)))
						))

						(# Get the objects)
						(var object_uuids (list))

						#{
							result = ""
							collection_name = endpoints["list"]["collection"]

							if !collection_name.nil?
								result += %{
									(var collection_uuids
										(func get_table_object_uuids_of_collection (
											"#{class_name}"
											"#{collection_name}"
										))
									)
									(var object_uuids collection_uuids.reverse)
								}
							end

							result
						}

						(# Render the result)
						(var result (hash (items (list))))

						(for uuid in object_uuids (
							(var obj (func get_table_object (uuid)))
							(if (is_nil obj) (continue))
							(var item (hash))

							(for key in fields.keys (
								(var value (func generate_result (
									key
									fields[key]
									obj
									schema
									\"#{class_name}\"
								)))

								(var item[key] value)
							))

							(result.items.push item)
						))

						(render_json result 200)
					}

					# Save the endpoint
					api_endpoint = api_slot.api_endpoints.find_by(
						path: class_name_snake_plural,
						method: "GET"
					)

					if api_endpoint.nil?
						ApiEndpoint.create(
							api_slot: api_slot,
							path: class_name_snake_plural,
							method: "GET",
							commands: code
						)
					else
						api_endpoint.commands = code
						api_endpoint.save
					end
				end

				if endpoints.include?("update")
					# Generate the update endpoint
					code = %{
						#{get_functions(schema, api.app, getters)}

						(# Get the params)
						(var uuid (get_param "uuid"))
						(var fields_str (get_param "fields"))

						(if (is_nil fields_str) (
							(var fields (hash (uuid (hash))))
						) else (
							(# Process the fields string)
							(var fields (func process_fields (fields_str)))
						))

						(var json (parse_json (get_body)))
						(var body_params (hash))

						#{
							generate_body_params_dx_code(properties)
						}

						(# Get the access token)
						(var access_token (get_header "Authorization"))

						(if (is_nil access_token) (
							(func render_validation_errors (
								(list (hash
									(error "authorization_header_missing")
									(status 400)
								))
							))
						))

						(# Make sure content type is json)
						(func validate_content_type_json ((get_header "Content-Type")))

						(# Get the session)
						(if (!(is_nil access_token)) (var session (func get_session (access_token))))

						(# Validate field types)
						#{
							generate_field_type_validations_dx_code(properties)
						}

						(# Validate too short and too long fields)
						#{
							generate_field_length_validations_dx_code(properties)
						}

						(# Validate validity of fields)
						#{
							generate_field_validity_validations_dx_code(properties)
						}

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

						(# Set the values)
						(for key in body_params.keys (
							(var value body_params[key])
							(if (is_nil value) (continue))

							(if (value == "") (
								(var obj.properties[key] nil)
							) else (
								(var obj.properties[key] value)
							))
						))

						(# Render the result)
						(var result (hash))

						(for key in fields.keys (
							(var value (func generate_result (
								key
								fields[key]
								obj
								schema
								\"#{class_name}\"
							)))

							(var result[key] value)
						))

						(render_json result 200)
					}

					# Save the endpoint
					path = "#{class_name_snake_plural}/:uuid"
					api_endpoint = api_slot.api_endpoints.find_by(
						path: path,
						method: "PUT"
					)

					if api_endpoint.nil?
						ApiEndpoint.create(
							api_slot: api_slot,
							path: path,
							method: "PUT",
							commands: code
						)
					else
						api_endpoint.commands = code
						api_endpoint.save
					end
				end

				# Generate the documentation for the current class
				api_docu += "# #{class_name}\n"
				api_docu += "## Resource representation\n\n"
				api_docu += "```\n"
				api_docu += "{\n"
				api_docu += "   \"uuid\": String"
				api_docu += "," unless properties.size == 0
				api_docu += "\n"

				properties.each do |prop_key, prop_data|
					api_docu += "   \"#{prop_key}\": #{prop_data["type"]}"
					api_docu += "[]" if prop_data["relationship"] == "multiple"
					api_docu += "," unless prop_key == properties.keys[-1]
					api_docu += "\n"
				end

				api_docu += "}\n"
				api_docu += "```\n\n"
				endpoints_data_list = Array.new

				endpoints.each do |endpoint_name, endpoint_data|
					case endpoint_name
					when "create"
						endpoints_data_list.push({
							type: "create",
							name: "Create #{class_name_snake_space}",
							url: endpoint_data["url"] || "/#{class_name_snake_plural}",
							url_params: endpoint_data["urlParams"],
							query_params: endpoint_data["queryParams"],
							body_params: endpoint_data["bodyParams"],
							method: "POST",
							description: endpoint_data["description"] || "Creates a new #{class_name_snake_space} for the user.",
							authenticated: true
						})
					when "retrieve"
						endpoints_data_list.push({
							type: "retrieve",
							name: "Retrieve #{class_name_snake_space}",
							url: endpoint_data["url"] || "/#{class_name_snake_plural}/:uuid",
							url_params: endpoint_data["urlParams"],
							query_params: endpoint_data["queryParams"],
							body_params: endpoint_data["bodyParams"],
							method: "GET",
							description: endpoint_data["description"] || "Retrieves the #{class_name_snake_space} with the given uuid.",
							authenticated: endpoint_data["authenticated"]
						})
					when "list"
						endpoints_data_list.push({
							type: "list",
							name: "List #{class_name_snake_space_plural}",
							url: endpoint_data["url"] || "/#{class_name_snake_plural}",
							url_params: endpoint_data["urlParams"],
							query_params: endpoint_data["queryParams"],
							body_params: endpoint_data["bodyParams"],
							method: "GET",
							description: endpoint_data["description"] || "Retrieves the #{class_name_snake_space_plural} with the given params.",
							authenticated: endpoint_data["authenticated"]
						})
					when "update"
						endpoints_data_list.push({
							type: "update",
							name: "Update #{class_name_snake_space}",
							url: endpoint_data["url"] || "/#{class_name_snake_plural}/:uuid",
							url_params: endpoint_data["urlParams"],
							query_params: endpoint_data["queryParams"],
							body_params: endpoint_data["bodyParams"],
							method: "PUT",
							description: endpoint_data["description"] || "Updates the #{class_name_snake_space} with the given uuid and returns it.",
							authenticated: true
						})
					when "set"
						endpoints_data_list.push({
							type: "set",
							name: "Set #{class_name_snake_space}",
							url: endpoint_data["url"] || "/#{class_name_snake_plural}",
							url_params: endpoint_data["urlParams"],
							query_params: endpoint_data["queryParams"],
							body_params: endpoint_data["bodyParams"],
							method: "PUT",
							description: endpoint_data["description"] || "Sets the #{class_name_snake_space}.",
							authenticated: true
						})
					when "upload"
						endpoints_data_list.push({
							type: "upload",
							name: "Upload #{class_name_snake_space}",
							url: endpoint_data["url"] || "/#{class_name_snake_plural}/:uuid",
							url_params: endpoint_data["urlParams"],
							query_params: endpoint_data["queryParams"],
							body_params: endpoint_data["bodyParams"],
							method: "PUT",
							description: endpoint_data["description"] || "Uploads the file for the #{class_name_snake_space} with the given uuid.",
							authenticated: true
						})
					else
						endpoints_data_list.push({
							type: "custom",
							name: "#{endpoint_name.capitalize} #{class_name_snake_space}",
							url: endpoint_data["url"],
							url_params: endpoint_data["urlParams"],
							query_params: endpoint_data["queryParams"],
							body_params: endpoint_data["bodyParams"],
							method: !endpoint_data["method"].nil? ? endpoint_data["method"].upcase : "",
							description: endpoint_data["description"],
							authenticated: endpoint_data["authenticated"]
						})
					end
				end

				# API methods table
				api_docu += "## API methods\n"
				api_docu += "Name | URL | Request method | Description\n"
				api_docu += "---- | --- | -------------- | -----------\n"

				endpoints_data_list.each do |endpoint_data|
					api_docu += endpoint_data[:name]
					api_docu += " | #{endpoint_data[:url]} "
					api_docu += " | #{endpoint_data[:method]} "
					api_docu += " | #{endpoint_data[:description]}\n"
				end

				api_docu += "\n"

				# API methods details
				endpoints_data_list.each do |endpoint_data|
					# Name and description
					api_docu += "## #{endpoint_data[:name]}\n"
					api_docu += "#{endpoint_data[:description]}\n\n"

					# Request method and url
					api_docu += "### Request\n"
					api_docu += "```\n"
					api_docu += "#{endpoint_data[:method]} #{endpoint_data[:url]}\n"
					api_docu += "```\n\n"

					# Header table
					authorization_data = endpoint_data[:authenticated]
					write_endpoint = ["POST", "PUT"].include?(endpoint_data[:method])

					if !authorization_data.nil? || write_endpoint
						api_docu += "#### Headers\n"
						api_docu += "Name | Type | Required\n"
						api_docu += "---- | ---- | --------\n"

						if authorization_data.is_a?(Hash)
							description = authorization_data["description"]
							description = "True" unless description

							api_docu += "Authorization | String | #{description}\n"
						elsif authorization_data == true || authorization_data.is_a?(String) || write_endpoint
							api_docu += "Authorization | String | True\n"
						end

						if write_endpoint
							api_docu += "Content-Type | String | True\n"
						end

						api_docu += "\n"
					end

					# URL params table
					if endpoint_data[:url].include?(":")
						api_docu += "#### URL params\n"
						api_docu += "Name | Type | Description\n"
						api_docu += "---- | ---- | -----------\n"

						if !endpoint_data[:url_params].nil?
							endpoint_data[:url_params].each do |param_name, param_data|
								api_docu += "#{param_name} | #{param_data["type"]} | #{param_data["description"]}\n"
							end
						elsif endpoint_data[:url].include?(":uuid")
							api_docu += "uuid | String | The uuid of the #{class_name_snake_space}\n"
						end
					end

					# Query params table
					api_docu += "#### Query params\n"
					api_docu += "Name | Type | Default value | Description\n"
					api_docu += "---- | ---- | ------------- | -----------\n"

					# fields param
					api_docu += "fields | String | uuid | List of parameters that should be returned, separated by comma\n"

					if !endpoint_data[:query_params].nil?
						endpoint_data[:query_params].each do |param_name, param_data|
							api_docu += "#{param_name} | #{param_data["type"]} | #{param_data["default"]} | #{param_data["description"]}\n"
						end
					end

					api_docu += "\n"

					if endpoint_data[:type] == "upload"
						api_docu += "#### Body\n"
						api_docu += "Provide the file data in the request body.\n"

						content_types = endpoints["upload"]["content_types"]

						if !content_types.nil?
							api_docu += "The following content types are accepted: "

							content_types.each do |content_type|
								api_docu += content_type
								api_docu += ", " unless content_type == content_types[-1]
							end

							api_docu += "\n"
						end

						api_docu += "\n"
					elsif ["POST", "PUT"].include?(endpoint_data[:method])
						# Body params table
						include_required = ["create", "set", "custom"].include?(endpoint_data[:type])

						api_docu += "#### Body params\n"
						api_docu += "Name | Type"
						api_docu += " | Required" if include_required
						api_docu += " | Description\n"
						api_docu += "---- | ----"
						api_docu += " | --------" if include_required
						api_docu += " | -----------\n"

						properties.each do |prop_key, prop_data|
							# Check if the property is already covered by a url param
							next if !endpoint_data[:url_params].nil? && !endpoint_data[:url_params][prop_key].nil?

							# Check if the property was excluded by the endpoints attribute in the properties hash
							next if !prop_data["endpoints"].nil? && !prop_data["endpoints"].include?(endpoint_data[:type])

							type = prop_data["type"]
							required = prop_data["required"]
							description = prop_data["description"]
							next if !ALLOWED_TYPES.include?(type)

							type = "String" if type.nil?
							required = false if required.nil?

							api_docu += prop_key
							api_docu += " | #{type}"
							api_docu += " | #{required}" if include_required
							api_docu += " | #{description}\n"
						end

						if !endpoint_data[:body_params].nil?
							endpoint_data[:body_params].each do |prop_key, prop_data|
								type = prop_data["type"]
								required = prop_data["required"]
								description = prop_data["description"]
								next if !ALLOWED_TYPES.include?(type)

								type = "String" if type.nil?

								api_docu += prop_key
								api_docu += " | #{type}"

								if endpoint_data[:method] == "POST"
									if required.is_a?(Hash)
										required_description = required["description"]
										required_description = "True" unless required_description

										api_docu += " | #{required_description}"
									elsif required == true || required.is_a?(String)
										api_docu += " | True"
									else
										api_docu += " | False"
									end
								end

								api_docu += " | #{description}\n"
							end
						end

						api_docu += "\n"
					end

					api_docu += "### Response\n"

					if endpoint_data[:type] == "list"
						api_docu += "If successful, this method returns a response body with the following structure:\n\n"
						api_docu += "```\n"
						api_docu += "{\n"
						api_docu += "   \"items\": [\n"
						api_docu += "      #{class_name_snake_space} resource\n"
						api_docu += "   ]\n"
						api_docu += "}\n"
						api_docu += "```\n\n"
					else
						api_docu += "If successful, this method returns a #{class_name_snake_space} resource in the response body.\n\n"
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

		api_slot.documentation = api_docu
		ValidationService.raise_unexpected_error(!api_slot.save)

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

	def get_schema_class_functions(schema, type_name, visited = [])
		result = {
			setters: [],
			getters: [],
			validators: [],
			preprocessors: []
		}

		# Check if the class exists in the schema
		return result unless schema[type_name]

		type = schema[type_name]

		# Check if we've already visited this class
		return result if visited.include?(type_name)

		properties = type["properties"]
		return result unless properties

		visited << type_name

		properties.each do |prop_name, prop_value|
			setter = prop_value["setter"]
			result[:setters].push(setter) if !setter.nil?

			getter = prop_value["getter"]
			result[:getters].push(getter) if !getter.nil?

			validator = prop_value["validator"]
			result[:validators].push(validator) if !validator.nil?

			preprocessor = prop_value["preprocessor"]
			result[:preprocessors].push(preprocessor) if !preprocessor.nil?

			sub_class_name = prop_value["type"]
			sub_result = get_schema_class_functions(
				schema,
				sub_class_name,
				visited
			)

			result[:setters].push(sub_result[:setters])
			result[:getters].push(sub_result[:getters])
			result[:validators].push(sub_result[:validators])
			result[:preprocessors].push(sub_result[:preprocessors])
		end

		visited.delete(type_name)

		result.each do |key, value|
			value.flatten!
			value.uniq!
		end

		return result
	end

	def hash_to_dx_hash(hash)
		values = ""

		hash.each do |key, value|
			if value.is_a?(String)
				values += "(#{key} \"#{value}\")\n"
			elsif value.is_a?(Hash)
				values += "(#{key} #{hash_to_dx_hash(value)})\n"
			elsif value.is_a?(Array)
				values += "(#{key} #{array_to_dx_list(value)})\n"
			else
				values += "(#{key} #{value})\n"
			end
		end

		return "(hash #{values})"
	end

	def array_to_dx_list(array)
		values = ""

		array.each do |value|
			if value.is_a?(String)
				values += "\"#{value}\"\n"
			elsif value.is_a?(Hash)
				values += "#{hash_to_dx_hash(value)}\n"
			elsif value.is_a?(Array)
				values += "#{array_to_dx_list(value)}\n"
			else
				values += "#{value}\n"
			end
		end

		return "(list #{values})"
	end

	def generate_state_dx_code(endpoint)
		result = "(var state (hash))\n"

		# Endpoint state vars
		if !endpoint.nil? && !endpoint["state"].nil?
			endpoint_state = endpoint["state"]
			result += "(var endpoint_state (func #{endpoint_state} ((get_params))))\n"

			result += "(for key in endpoint_state.keys (\n"
			result += "(var state[key] endpoint_state[key])\n"
			result += "))\n"
		end

		result
	end

	def generate_body_params_dx_code(schema_properties)
		result = ""

		schema_properties.each do |prop_key, prop_value|
			next if !ALLOWED_TYPES.include?(prop_value["type"])
			result += "(var body_params[\"#{prop_key}\"] json[\"#{prop_key}\"])\n"
		end

		result
	end

	def generate_missing_field_validations_dx_code(schema_properties)
		result = "(var errors (list))"

		schema_properties.each do |prop_key, prop_value|
			next unless prop_value["required"]
			result += %{
				(if (is_nil body_params["#{prop_key}"]) (
					(errors.push (hash
						(error "#{prop_key}_missing")
						(status 400)
					))
				))
			}
		end

		result += "(func render_validation_errors (errors))"
		result
	end

	def generate_field_type_validations_dx_code(schema_properties)
		result = "(var errors (list))"

		schema_properties.each do |prop_key, prop_value|
			if prop_value["type"].nil? || prop_value["type"] == "String"
				condition = "(body_params[\"#{prop_key}\"].class != \"String\")"
			elsif prop_value["type"] == "Boolean"
				condition = "((body_params[\"#{prop_key}\"] != true) and (body_params[\"#{prop_key}\"] != false))"
			elsif prop_value["type"] == "Integer"
				condition = "(body_params[\"#{prop_key}\"].class != \"Integer\")"
			elsif prop_value["type"] == "Float"
				condition = "(body_params[\"#{prop_key}\"].class != \"Float\")"
			elsif prop_value["relationship"] == "multiple"
				condition = "(body_params[\"#{prop_key}\"].class != \"Array\")"
			else
				next
			end

			result += %{
				(if (!(is_nil body_params["#{prop_key}"])) (
					(if #{condition} (
						(errors.push (hash
							(error "#{prop_key}_wrong_type")
							(status 400)
						))
					))
				))
			}
		end

		result += "(func render_validation_errors (errors))"
		result
	end

	def generate_field_length_validations_dx_code(schema_properties)
		result = "(var errors (list))"

		schema_properties.each do |prop_key, prop_value|
			next if prop_value["minLength"].nil? && prop_value["maxLength"].nil?
			next if !prop_value["type"].nil? && prop_value["type"] != "String"

			if !prop_value["minLength"].nil?
				result += %{
					(if (
						(!(is_nil body_params["#{prop_key}"]))
						and (body_params["#{prop_key}"].length < #{prop_value["minLength"]})
					)
						(errors.push (hash
							(error "#{prop_key}_too_short")
							(status 400)
						))
					)
				}
			end

			if !prop_value["maxLength"].nil?
				result += %{
					(if (
						(!(is_nil body_params["#{prop_key}"]))
						and (body_params["#{prop_key}"].length > #{prop_value["maxLength"]})
					)
						(errors.push (hash
							(error "#{prop_key}_too_long")
							(status 400)
						))
					)
				}
			end
		end

		result += "(func render_validation_errors (errors))"
		result
	end

	def generate_field_validity_validations_dx_code(schema_properties)
		result = "(var errors (list))"

		schema_properties.each do |prop_key, prop_value|
			next unless prop_value["validator"]

			result += %{
				(if (
					(!(is_nil body_params["#{prop_key}"]))
					and (!(func #{prop_value["validator"]} (body_params["#{prop_key}"])))
				) (
					(errors.push (hash
						(error "#{prop_key}_invalid")
						(status 400)
					))
				))
			}
		end

		result += "(func render_validation_errors (errors))"
		result
	end

	def get_functions(schema, app, getters)
		return %{
			(var schema #{hash_to_dx_hash(schema)})

			(def render_errors (errors status) (
				(# params: errors: list, status: int)
				(render_json (hash (errors errors)) status)
			))

			(def render_validation_errors (validations status) (
				(# params: validations: list<hash<error: string, status: number>>)
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
						(var error_code "session_does_not_exist")
						(var status_code 404)
					) elseif (error.code == 1) (
						(# Can't use old access token)
						(var error_code "cannot_use_old_access_token")
						(var status_code 403)
					) else (
						(# Session needs to be renewed)
						(var error_code "access_token_must_be_renewed")
						(var status_code 403)
					))

					(func render_validation_errors (
						(list (hash
							(error error_code)
							(status status_code)
						))
					))
				))

				(# Check if the session belongs to the app)
				(if (session.app_id != #{app.id}) (
					(# Action not allowed)
					(func render_validation_errors (
						(list (hash
							(error "action_not_allowed")
							(status 403)
						))
					))
				))

				(return session)
			))

			(def create_table_object (user_id table_name properties) (
				(# params: user_id: int, table_name: string, properties: Hash)
				(catch (
					(TableObject.create user_id table_name properties)
				) (
					(var error errors#0)

					(if (((error.code == 0) or (error.code == 2)) or (error.code == 3)) (
						(# Table or user does not exist, or object didn't save)
						(func render_validation_errors (
							(list (hash
								(error "unexpected_error")
								(status 500)
							))
						))
					) else (
						(# Action not allowed)
						(func render_validation_errors (
							(list (hash
								(error "action_not_allowed")
								(status 403)
							))
						))
					))
				))
			))

			(def get_table_object (uuid user_id) (
				(# params: uuid: string, user_id: int)
				(if (is_nil uuid) (return nil))

				(catch (
					(var obj (TableObject.get uuid))
				) (
					(# Action not allowed)
					(func render_validation_errors (
						(list (hash
							(error "action_not_allowed")
							(status 403)
						))
					))
				))

				(if (is_nil obj) (
					(return nil)
				) else (
					(# Check if the table object belongs to the user and to the table)
					(if ((!(is_nil user_id)) and (obj.user_id != user_id)) (
						(# Action not allowed)
						(func render_validation_errors (
							(list (hash
								(error "action_not_allowed")
								(status 403)
							))
						))
					))

					(return obj)
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

			(def validate_content_type_json (content_type) (
				(# params: content_type: String)
				(if ((is_nil content_type) or (!(content_type.contains "application/json"))) (
					(# Content-Type not supported error)
					(func render_validation_errors (
						(list (hash
							(error "content_type_not_supported")
							(status 415)
						))
					))
				))
			))

			(def get_table_object_uuids_of_collection (table_name collection_name) (
				(catch (
					(Collection.get_table_object_uuids table_name collection_name)
				) (
					(# Unexpected error)
					(func render_validation_errors (
						(list (hash
							(error "unexpected_error")
							(status 500)
						))
					))
				))
			))
		}
	end
end
