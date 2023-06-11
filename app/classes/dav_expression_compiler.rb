class DavExpressionCompiler
	def compile(props)
		@api_slot = props[:api_slot]
		@defined_functions = Array.new
		@functions_to_define = Array.new

		# Parse and compile the commands
		@parser = Sexpistol.new
		@parser.ruby_keyword_literals = true
		ast = @parser.parse_string(props[:commands])
		code = ""

		ast.each do |element|
			code += "#{compile_command(element)}\n"
		end

		# Define functions
		functions_code = ""
		@functions_to_define.each do |function|
			functions_code += compile_function_definition(function)
		end

		# Define built-in methods
		methods_code = %{
			def _method_call(method_name, **params)
				errors = Array.new

				case method_name
				when 'parse_json'
					json = params[:json]

					if json.length < 2
						return {}
					else
						return JSON.parse(json)
					end
				when 'get_body'
					body = @vars[:body]

					if body.class == StringIO
						return body.string
					elsif body.class == Tempfile
						return body.read
					else
						return body
					end
				when 'get_error'
					error = ApiError.find_by(api_slot: @vars[:api_slot], code: params[:code])
					return {
						"code" => error.code,
						"message" => error.message
					}
				when 'get_app'
					id = params[:id].to_i
					app = @vars[:apps][id]

					if app.nil?
						app = App.find_by(id: id)
						@vars[:apps][id] = app if !app.nil?
					end

					return app
				when 'get_table'
					id = params[:id].to_i
					name = params[:name]
					table = @vars[:tables][id]

					if table.nil?
						if !name.nil?
							table = Table.find_by(name: name)
						else
							table = Table.find_by(id: id)
						end

						@vars[:tables][id] = table if !table.nil?
					end

					return table
				when 'get_table_object'
					uuid = params[:uuid]
					return nil if !uuid.is_a?(String)

					obj = @vars[:table_objects][uuid]
					return obj if !obj.nil?

					key = "table_object:\#\{uuid\}"
					obj_json = @vars[:redis].get(key)

					if obj_json.nil?
						# Get the table object from the database
						obj = TableObject.find_by(uuid: uuid)
						return nil if obj.nil?

						# Save the table object in redis
						obj_data = {
							'id' => obj.id,
							'user_id' => obj.user_id,
							'table_id' => obj.table_id,
							'file' => obj.file,
							'etag' => obj.etag,
							'properties' => Hash.new
						}

						obj.table_object_properties.each do |prop|
							prop_type = TablePropertyType.find_by(table_id: obj.table_id, name: prop.name)
							type = 0
							type = prop_type.data_type if !prop_type.nil?
							value = prop.value

							if type == 1
								value = value == 'true'
							elsif type == 2
								value = Integer value rescue value
							elsif type == 3
								Float value rescue value
							end

							obj_data['properties'][prop.name] = value
						end

						@vars[:redis].set(key, obj_data.to_json)
						obj_data['uuid'] = uuid

						obj_holder = TableObjectHolder.new(obj_data)
						@vars[:table_objects][uuid] = obj_holder
						return obj_holder
					else
						obj_data = JSON.parse(obj_json)
						obj_data['uuid'] = uuid

						obj_holder = TableObjectHolder.new(obj_data)
						@vars[:table_objects][uuid] = obj_holder
						return obj_holder
					end
				when 'get_table_object_properties'
					user_id = params[:user_id]
					table_id = params[:table_id]
					table_object_uuid = params[:table_object_uuid]
					name = params[:name]
					return nil if !user_id.is_a?(Integer)
					return nil if !table_id.is_a?(Integer)
					return nil if !table_object_uuid.is_a?(String) && !table_object_uuid.nil?
					return nil if !name.is_a?(String) && !name.nil?

					if user_id <= 0
						user_id_str = '*'
					else
						user_id_str = user_id.to_s
					end

					if table_id <= 0
						table_id_str = '*'
					else
						table_id_str = table_id.to_s
					end

					table_object_uuid = '*' if table_object_uuid.nil?
					name = '*' if name.nil?

					return @vars[:redis].keys("table_object_property:\#\{user_id_str\}:\#\{table_id_str\}:\#\{table_object_uuid\}:\#\{name\}:*")
				when 'render_json'
					data = params[:data]
					status = params[:status]

					@vars[:response] = {
						data: data,
						status: status,
						file: false
					}
				when 'render_file'
					data = params[:data]
					type = params[:type]
					filename = params[:filename]
					status = params[:status]

					@vars[:response] = {
						data: data,
						status: status,
						file: true,
						headers: {
							"Content-Length" => data == nil ? 0 : data.size
						},
						type: type,
						filename: filename
					}
				when 'contains_all'
					original_array = params[:original_array]
					comparing_array = params[:comparing_array]
					intersecting_array = original_array & comparing_array
					return intersecting_array.size == comparing_array.size
				when 'convert_value_to_data_type'
					value = params[:value]
					data_type = params[:data_type]

					return value == 'true' if data_type == 1
					return Integer value rescue value if data_type == 2
					return Float value rescue value if data_type == 3
					return value
				when 'User.get'
					id = params[:id]
					return User.find_by(id: id)
				when 'User.is_provider'
					user_id = params[:user_id]

					user = User.find_by(id: user_id)

					if user.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					return !user.provider.nil?
				when 'Session.get'
					token = params[:access_token]
					session = Session.find_by(token: token)

					if session.nil?
						# Check if there is a session with old_token = token
						session = Session.find_by(old_token: token)

						if session.nil?
							# Session does not exist
							raise RuntimeError, [{"code" => 0}].to_json
						else
							# The old token was used
							# Delete the session, as the token may be stolen
							session.destroy!
							raise RuntimeError, [{"code" => 1}].to_json
						end
					else
						# Check if the session needs to be renewed
						if Rails.env.production? && (Time.now - session.updated_at) > 1.day
							raise RuntimeError, [{"code" => 2}].to_json
						end
					end

					return session
				when 'Table.get'
					id = params[:id]

					table = _method_call('get_table', id: id)

					if !table.nil? && _method_call('get_app', id: table.app_id) != @vars[:api_slot].api.app
						# Action not allowed
						raise RuntimeError, [{"code" => 1}].to_json
					end

					return table
				when 'Table.get_table_objects'
					table_name = params[:table_name]
					user_id = params[:user_id]

					table = _method_call('get_table', name: table_name)
					return nil if !table

					table_app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					if table_app != api_app
						# Action not allowed error
						raise RuntimeError, [{"code" => 1}].to_json
					end

					if user_id.nil?
						objects = table.table_objects.to_a
					else
						objects = table.table_objects.where(user_id: user_id.to_i).to_a
					end

					holders = Array.new
					objects.each { |obj| holders.push(TableObjectHolder.new(obj)) }

					return holders
				when 'Table.get_table_object_uuids'
					table_name = params[:table_name]
					user_id = params[:user_id]

					table = _method_call('get_table', name: table_name)
					return nil if !table

					table_app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					if table_app != api_app
						# Action not allowed error
						raise RuntimeError, [{"code" => 1}].to_json
					end

					if user_id.nil?
						objects = table.table_objects.to_a
					else
						objects = table.table_objects.where(user_id: user_id.to_i).to_a
					end

					uuids = Array.new
					objects.each { |obj| uuids.push(obj.uuid) }
					return uuids
				when 'TableObject.create'
					user_id = params[:user_id]
					table_id = params[:table_id]
					properties = params[:properties]

					# Get the table
					if table_id.is_a?(String)
						# Get the table by the name
						table = _method_call('get_table', name: table_id)
					else
						# Get the table by the id
						table = _method_call('get_table', id: table_id)
					end

					# Check if the table exists
					if table.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					table_app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table belongs to the same app as the api
					if table_app != api_app
						raise RuntimeError, [{"code" => 1}].to_json
					end

					# Check if the user exists
					user = User.find_by(id: user_id)
					if user.nil?
						raise RuntimeError, [{"code" => 2}].to_json
					end

					# Create the table object
					obj = TableObject.new
					obj.user = user
					obj.table = table
					obj.uuid = SecureRandom.uuid

					if !obj.save
						# Unexpected error
						raise RuntimeError, [{"code" => 3}].to_json
					end

					# Create the properties
					properties.each do |key, value|
						prop = TableObjectProperty.new
						prop.table_object = obj
						prop.name = key
						prop.value = value

						raise RuntimeError, [{"code" => 3}].to_json if prop.save
					end

					# Return the table object
					return TableObjectHolder.new(obj)
				when 'TableObject.create_file'
					user_id = params[:user_id]
					table_id = params[:table_id]
					ext = params[:ext]
					type = params[:type]
					file = params[:file]
					properties = params[:properties]

					# Get the table
					table = _method_call('get_table', id: table_id)

					# Check if the table exists
					if table.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					table_app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table belongs to the same app as the api
					if table_app != api_app
						raise RuntimeError, [{"code" => 1}].to_json
					end

					# Check if the user exists
					user = User.find_by(id: user_id)

					if user.nil?
						raise RuntimeError, [{"code" => 2}].to_json
					end

					# Create the table object
					obj = TableObject.new
					obj.user = user
					obj.table = table
					obj.uuid = SecureRandom.uuid
					obj.file = true

					file_size = file.size

					# Check if the user has enough free storage
					free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage

					if free_storage < file_size
						raise RuntimeError, [{"code" => 3}].to_json
					end

					# Save the table object
					if !obj.save
						raise RuntimeError, [{"code" => 4}].to_json
					end

					begin
						# Upload the file
						result = BlobOperationsService.upload_blob(obj, StringIO.new(file), type)
						etag = result.etag
						etag = etag[1...etag.size-1]
					rescue Exception => e
						raise RuntimeError, [{"code" => 5}].to_json
					end

					# Save extension as property
					ext_prop = TableObjectProperty.new(table_object: obj, name: Constants::EXT_PROPERTY_NAME, value: ext)

					# Save etag as property
					etag_prop = TableObjectProperty.new(table_object: obj, name: Constants::ETAG_PROPERTY_NAME, value: etag)

					# Save the file size as property
					size_prop = TableObjectProperty.new(table_object: obj, name: Constants::SIZE_PROPERTY_NAME, value: file_size)

					# Save the content type as property
					type_prop = TableObjectProperty.new(table_object: obj, name: Constants::TYPE_PROPERTY_NAME, value: type)

					# Update the used storage
					UtilsService.update_used_storage(user, table.app, file_size)

					# Save that user uses the app
					app_user = AppUser.find_by(app: table.app, user: user)

					if app_user.nil?
						app_user = AppUser.new(app: table.app, user: user)
						app_user.save
					end

					# Create the properties
					prohibited_property_names = [
						Constants::EXT_PROPERTY_NAME,
						Constants::ETAG_PROPERTY_NAME,
						Constants::SIZE_PROPERTY_NAME,
						Constants::TYPE_PROPERTY_NAME
					]

					properties.each do |key, value|
						next if prohibited_property_names.include?(key)

						prop = TableObjectProperty.new
						prop.table_object = obj
						prop.name = key
						prop.value = value

						raise RuntimeError, [{"code" => 6}].to_json if !prop.save
					end

					if !ext_prop.save || !etag_prop.save || !size_prop.save || !type_prop.save
						raise RuntimeError, [{"code" => 6}].to_json
					end

					return TableObjectHolder.new(obj)
				when 'TableObject.get'
					uuid = params[:uuid]

					obj = _method_call('get_table_object', uuid: uuid)
					return nil if obj.nil?

					table = _method_call('get_table', id: obj.table_id)
					app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table of the table object belongs to the same app as the api
					if app != api_app
						raise RuntimeError, [{"code" => 0}].to_json
					end

					return obj
				when 'TableObject.get_file'
					uuid = params[:uuid]

					obj = _method_call('get_table_object', uuid: uuid)
					return nil if obj.nil? || !obj.obj.file

					table = _method_call('get_table', id: obj.table_id)
					app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table of the table object belongs to the same app as the api
					if app != api_app
						raise RuntimeError, [{"code" => 0}].to_json
					end

					begin
						download_result = BlobOperationsService.download_blob(obj.obj)
						return download_result[1]
					rescue => e
						return nil
					end
				when 'TableObject.update'
					uuid = params[:uuid]
					properties = params[:properties]

					# Get the table object
					obj = _method_call('get_table_object', uuid: uuid)

					# Check if the table object exists
					if obj.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					# Make sure the object is not a file
					if obj.obj.file
						raise RuntimeError, [{"code" => 1}].to_json
					end

					table = _method_call('get_table', id: obj.table_id)
					app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table of the table object belongs to the same app as the api
					if app != api_app
						raise RuntimeError, [{"code" => 2}].to_json
					end

					# Update the properties of the table object
					properties.each do |key, value|
						next if !value
						obj[key] = value
					end

					return obj
				when 'TableObject.update_file'
					uuid = params[:uuid]
					ext = params[:ext]
					type = params[:type]
					file = params[:file]

					# Get the table object
					obj = _method_call('get_table_object', uuid: uuid)

					# Check if the table object exists
					if obj.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					# Check if the table object is a file
					if !obj.obj.file
						raise RuntimeError, [{"code" => 1}].to_json
					end

					table = _method_call('get_table', id: obj.table_id)
					app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table of the table object belongs to the same app as the api
					if app != api_app
						raise RuntimeError, [{"code" => 2}].to_json
					end

					# Get the properties
					size = obj[Constants::SIZE_PROPERTY_NAME].to_i

					user = obj.user
					file_size = file.size
					old_file_size = size
					file_size_diff = file_size - old_file_size
					free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage

					# Check if the user has enough free storage
					if free_storage < file_size_diff
						raise RuntimeError, [{"code" => 3}].to_json
					end

					begin
						# Upload the new file
						result = BlobOperationsService.upload_blob(obj.obj, StringIO.new(file), type)
						etag = result.etag
						etag = etag[1...etag.size-1]
					rescue Exception => e
						raise RuntimeError, [{"code" => 4}].to_json
					end

					# Update the properties
					obj[Constants::EXT_PROPERTY_NAME] = ext
					obj[Constants::ETAG_PROPERTY_NAME] = etag
					obj[Constants::SIZE_PROPERTY_NAME] = file_size
					obj[Constants::TYPE_PROPERTY_NAME] = type

					# Update the used storage
					UtilsService.update_used_storage(obj.user, app, file_size_diff)

					return obj
				when 'TableObject.set_price'
					uuid = params[:uuid]
					price = params[:price]
					currency = params[:currency]

					# Get the table object
					obj = _method_call('get_table_object', uuid: uuid)

					# Check if the table object exists
					if obj.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					table = _method_call('get_table', id: obj.table_id)
					app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table of the table object belongs to the same app as the api
					if app != api_app
						raise RuntimeError, [{"code" => 1}].to_json
					end

					# Try to get the price of the table object with the currency
					obj_price = obj.obj.table_object_prices.find_by(currency: currency.downcase)

					if obj_price.nil?
						# Create a new price
						obj_price = TableObjectPrice.new(
							table_object_id: obj.id,
							price: price,
							currency: currency
						)
					else
						# Update the price
						obj_price.price = price
					end

					if !obj_price.save
						raise RuntimeError, [{"code" => 2}].to_json
					end
				when 'TableObject.get_price'
					uuid = params[:uuid]
					currency = params[:currency]

					# Get the table object
					obj = _method_call('get_table_object', uuid: uuid)

					# Check if the table object exists
					return nil if obj.nil?

					table = _method_call('get_table', id: obj.table_id)
					app = _method_call('get_app', id: table.app_id)
					api_app = _method_call('get_app', id: @vars[:api_slot].api.app_id)

					# Check if the table of the table object belongs to the same app as the api
					if app != api_app
						raise RuntimeError, [{"code" => 0}].to_json
					end

					# Try to get the price of the table object with the currency
					obj_price = obj.obj.table_object_prices.find_by(currency: currency.downcase)
					return nil if obj_price.nil?
					return obj_price.price
				when 'TableObject.get_cdn_url'
					uuid = params[:uuid]
					query_params = params[:params]
					return nil if uuid.nil?

					if query_params.nil?
						return "https://\#\{ENV['BUCKET_NAME_READ']\}.fra1.cdn.digitaloceanspaces.com/\#\{uuid\}"
					else
						return "https://\#\{ENV['BUCKET_NAME_READ']\}.fra1.cdn.digitaloceanspaces.com/\#\{uuid\}?\#\{query_params.to_query\}"
					end
				when 'TableObjectUserAccess.create'
					table_object_id = params[:table_object_id]
					user_id = params[:user_id]
					alias_table_name = params[:alias_table_name]

					# Check if there is already a TableObjectUserAccess object
					if table_object_id.is_a?(String)
						# Get the id of the table object
						obj = _method_call('get_table_object', uuid: table_object_id)
					else
						obj = _method_call('get_table_object', id: table_object_id)
					end

					if obj.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					# Try to find the table
					table = _method_call('get_table', name: alias_table_name)

					if table.nil?
						raise RuntimeError, [{"code" => 1}].to_json
					end

					# Find the access and return it
					access = TableObjectUserAccess.find_by(
						table_object_id: obj.id,
						user_id: user_id,
						table_alias: table.id
					)

					if access.nil?
						access = TableObjectUserAccess.create(
							table_object_id: table_object_id,
							user_id: user_id,
							table_alias: table.id
						)
					end

					return access
				when 'Collection.add_table_object'
					collection_name = params[:collection_name]
					table_object_id = params[:table_object_id]

					if table_object_id.is_a?(String)
						# Get the table object by uuid
						obj = _method_call('get_table_object', uuid: table_object_id)
					else
						# Get the table object by id
						obj = TableObject.find_by(id: table_object_id)
					end

					if obj.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					obj = TableObjectHolder.new(obj) if obj.is_a?(TableObject)

					table = _method_call('get_table', id: obj.table_id)

					# Try to find the collection
					collection = Collection.find_by(name: collection_name, table: table)

					if !collection
						# Create the collection
						collection = Collection.new(name: collection_name, table: table)
						collection.save
					end

					# Try to find the TableObjectCollection
					obj_collection = TableObjectCollection.find_by(table_object_id: obj.id, collection: collection)

					if obj_collection.nil?
						# Create the TableObjectCollection
						obj_collection = TableObjectCollection.new(table_object_id: obj.id, collection: collection)
						obj_collection.save
					end

					return obj_collection
				when 'Collection.remove_table_object'
					collection_name = params[:collection_name]
					table_object_id = params[:table_object_id]

					if table_object_id.is_a?(String)
						# Get the table object by uuid
						obj = _method_call('get_table_object', uuid: table_object_id)
					else
						# Get the table object by id
						obj = TableObject.find_by(id: table_object_id)
					end

					if obj.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					obj = TableObjectHolder.new(obj) if obj.is_a?(TableObject)

					table = _method_call('get_table', id: obj.table_id)

					# Find the collection
					collection = Collection.find_by(name: collection_name, table: table)

					if collection.nil?
						raise RuntimeError, [{"code" => 1}].to_json
					end

					# Find and delete the TableObjectCollection
					obj_collection = TableObjectCollection.find_by(table_object_id: obj.id, collection: collection)
					obj_collection.destroy! if !obj_collection.nil?
				when 'Collection.get_table_objects'
					table_id = params[:table_id]
					collection_name = params[:collection_name]

					# Try to find the table
					table = _method_call('get_table', id: table_id)

					if table.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					# Try to find the collection
					collection = Collection.find_by(name: collection_name, table: table)

					if collection.nil?
						return Array.new
					else
						holders = Array.new
						collection.table_objects.each { |obj| holders.push(TableObjectHolder.new(obj)) }
						return holders
					end
				when 'Collection.get_table_object_uuids'
					table_name = params[:table_name]
					collection_name = params[:collection_name]

					# Try to find the table
					table = _method_call('get_table', name: table_name)

					if table.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					# Try to find the collection
					collection = Collection.find_by(name: collection_name, table: table)

					if collection.nil?
						return Array.new
					else
						uuids = Array.new
						collection.table_objects.each { |obj| uuids.push(obj.uuid) }
						return uuids
					end
				when 'TableObject.find_by_property'
					all_user = params[:user_id] == "*"
					user_id = all_user ? -1 : params[:user_id]
					table_id = params[:table_id]
					property_name = params[:property_name]
					property_value = params[:property_value]
					exact = params[:exact].nil? ? true : params[:exact]
					objects = Hash.new

					if all_user
						property_keys = _method_call('get_table_object_properties', user_id: 0, table_id: table_id, table_object_uuid: nil, name: property_name)
					else
						property_keys = _method_call('get_table_object_properties', user_id: user_id, table_id: table_id, table_object_uuid: nil, name: property_name)
					end

					if exact
						property_keys.each do |key|
							value = @vars[:redis].get(key)
							value = _method_call('convert_value_to_data_type', value: value, data_type: key.split(':').last.to_i)

							if value == property_value
								# Get the table object id from the key
								table_object_uuid = key.split(':')[3]
								next if objects.include?(table_object_uuid)

								# Add the table object to the list of objects
								obj = _method_call('get_table_object', uuid: table_object_uuid)
								next if obj.nil?

								objects[table_object_uuid] = obj
							end
						end
					else
						property_keys.each do |key|
							value = @vars[:redis].get(key)
							value = _method_call('convert_value_to_data_type', value: value, data_type: key.split(':').last.to_i)

							if value.include?(property_value)
								# Get the table object id from the key
								table_object_uuid = key.split(':')[3]
								next if objects.include?(table_object_uuid)

								# Add the table object to the list of objects
								obj = _method_call('get_table_object', uuid: table_object_uuid)
								next if obj.nil?

								objects[table_object_uuid] = obj
							end
						end
					end

					return objects.values
				when 'Purchase.create'
					user_id = params[:user_id]
					provider_name = params[:provider_name]
					provider_image = params[:provider_image]
					product_name = params[:product_name]
					product_image = params[:product_image]
					price = params[:price]
					currency = params[:currency]
					table_objects = params[:table_objects]

					# Get the user
					user = User.find_by(id: user_id)

					if user.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					# Check the property types
					if !provider_name.is_a?(String) || !provider_image.is_a?(String) || !product_name.is_a?(String) || !product_image.is_a?(String) || !price.is_a?(Integer) || !currency.is_a?(String) || !table_objects.is_a?(Array)
						raise RuntimeError, [{"code" => 1}].to_json
					end

					# Validate the price
					if price < 0
						raise RuntimeError, [{"code" => 2}].to_json
					end

					# Make sure there is at least one table object
					if table_objects.count == 0
						raise RuntimeError, [{"code" => 3}].to_json
					end

					# Get the table objects
					objs = Array.new

					table_objects.each do |uuid|
						obj = TableObject.find_by(uuid: uuid)

						if obj.nil?
							raise RuntimeError, [{"code" => 4}].to_json
						end

						objs.push(obj)
					end

					# Check if the table objects belong to the same user
					obj_user = objs.first.user
					i = 1

					while i < objs.count
						if objs[i].user != obj_user
							raise RuntimeError, [{"code" => 5}].to_json
						end

						i += 1
					end

					# Check if the user of the table objects has a provider
					if price > 0 && obj_user.provider.nil?
						raise RuntimeError, [{"code" => 6}].to_json
					end

					# Create the purchase
					purchase = Purchase.new(
						user: user,
						uuid: SecureRandom.uuid,
						provider_name: provider_name,
						provider_image: provider_image,
						product_name: product_name,
						product_image: product_image,
						price: price,
						currency: currency
					)

					if price == 0
						purchase.completed = true
					else
						# Create a stripe customer for the user, if the user has none
						if user.stripe_customer_id.nil?
							customer = Stripe::Customer.create(email: user.email)
							user.stripe_customer_id = customer.id
							ValidationService.raise_unexpected_error(!user.save)
						end

						# Create a payment intent
						begin
							payment_intent = Stripe::PaymentIntent.create({
								customer: user.stripe_customer_id,
								amount: price,
								currency: currency.downcase,
								confirmation_method: 'manual',
								application_fee_amount: (price * 0.2).round,
								transfer_data: {
									destination: obj_user.provider.stripe_account_id
								}
							})
						rescue Stripe::CardError => e
							raise RuntimeError, [{"code" => 7}].to_json
						end

						purchase.payment_intent_id = payment_intent.id
					end

					# Create the TableObjectPurchases
					objs.each do |obj|
						obj_purchase = TableObjectPurchase.new(
							table_object: obj,
							purchase: purchase
						)

						if !obj_purchase.save
							raise RuntimeError, [{"code" => 8}].to_json
						end
					end

					return purchase
				when 'Purchase.get_table_object'
					purchase_id = params[:purchase_id]
					user_id = params[:user_id]

					purchase = Purchase.find_by(id: purchase_id)

					if purchase.nil?
						raise RuntimeError, [{"code" => 0}].to_json
					end

					user = User.find_by(id: user_id)

					if user.nil?
						raise RuntimeError, [{"code" => 1}].to_json
					end

					if purchase.user != user
						raise RuntimeError, [{"code" => 2}].to_json
					end

					if !purchase.completed
						raise RuntimeError, [{"code" => 3}].to_json
					end

					return TableObjectHolder.new(purchase.table_object)
				when 'Purchase.find_by_user_and_table_object'
					user_id = params[:user_id]
					table_object_id = params[:table_object_id]

					if table_object_id.class == Integer
						# table_object_id is id
						table_object = TableObject.find_by(id: table_object_id)
						return nil if table_object.nil?

						return table_object.purchases.find_by(user_id: user_id, completed: true)
					else
						# table_object_id is uuid
						table_object = TableObject.find_by(uuid: table_object_id)
						return nil if table_object.nil?

						return table_object.purchases.find_by(user_id: user_id, completed: true)
					end
				when 'DateTime.now'
					return DateTime.now
				when 'Math.round'
					var = params[:var]
					rounding = params[:rounding].nil? ? 2 : params[:rounding]

					return var if var.class != Float || rounding.class != Integer
					rounded_value = var.round(rounding)
					rounded_value = var.round if rounded_value == var.round
					return rounded_value
				when 'Regex.match'
					string = params[:string]
					regex = params[:regex]

					return Hash.new if string == nil || regex == nil
					match = regex.match(string)
					return match == nil ? Hash.new : match.named_captures
				when 'Regex.check'
					string = params[:string]
					regex = params[:regex]

					return false if string == nil || regex == nil
					return regex.match?(string)
				when 'Blurhash.encode'
					image_data = params[:image_data]

					begin
						image = Magick::ImageList.new
		
						if image_data.class == StringIO
							image.from_blob(image_data.string)
						elsif image_data.class == Tempfile
							image_data.rewind
							image.from_blob(image_data.read)
						else
							image.from_blob(image_data)
						end

						return Blurhash.encode(image.columns, image.rows, image.export_pixels)
					rescue
						return nil
					end
				when 'Image.get_details'
					image_data = params[:image_data]

					begin
						result = Hash.new
						image = Magick::ImageList.new

						if image_data.class == StringIO
							image.from_blob(image_data.string)
						elsif image_data.class == Tempfile
							image_data.rewind
							image.from_blob(image_data.read)
						else
							image.from_blob(image_data)
						end

						result['width'] = image.columns
						result['height'] = image.rows
						return result
					rescue
						result['width'] = -1
						result['height'] = -1
						return result
					end
				end
			end
		}

		return functions_code + methods_code + code
	end

	def run(props)
		api_slot = props[:api_slot]

		# Define necessary vars
		@vars = {
			api_slot: api_slot,
			env: Hash.new
		}

		# Get the environment variables
		api_slot.api_env_vars.each do |env_var|
			@vars[:env][env_var.name] = UtilsService.convert_env_value(env_var.class_name, env_var.value)
		end

		if props[:request].nil?
			@vars[:params] = Hash.new
			@vars[:body] = nil
			@vars[:headers] = Hash.new
		else
			@vars[:params] = props[:request][:params]
			@vars[:body] = props[:request][:body]
			@vars[:headers] = props[:request][:headers]
		end

		@vars[:apps] = Hash.new
		@vars[:tables] = Hash.new
		@vars[:table_objects] = Hash.new
		@vars[:table_objects_table_id] = Hash.new
		@vars[:table_objects_user_id_table_id] = Hash.new
		@vars[:redis] = UtilsService.redis

		eval props[:code]
	end

	private
	def compile_command(command, nested = false)
		if command.class == Array
			if command[0].class == Array && (!command[1] || command[1].class == Array)
				# Command contains commands
				code = ""
				command.each { |c| code += "#{compile_command(c, nested)}\n" }
				return code
			end

			# Command is a function call
			case command[0]
			when :var
				# Check usage of []
				matchdata = command[1].to_s.match /^(?<varname>[a-zA-Z0-9_\-\.]{1,})\[(?<value>[a-zA-Z0-9_\-\"\.]{0,})\]$/
				val = compile_command(command[2], true)
				val.strip! if val.is_a?(String)

				if val.is_a?(String) && val.start_with?("if")
					val = "(#{val})"
				end

				if !matchdata.nil?
					matchdata_varname = matchdata["varname"]
					matchdata_value = matchdata["value"]
					splitted_varname = matchdata_varname.split(".")

					if splitted_varname[-1] == "properties"
						matchdata_varname = splitted_varname[0..-2].join(".")
					end

					if !matchdata_value.nil?
						if matchdata_value[0] == "\"" && matchdata_value[-1] == "\""
							# value is a string
							result = "#{matchdata_varname}[#{matchdata_value}] = #{val}"
						else
							# value is an expression or var name
							result = "#{matchdata_varname}[#{compile_command(matchdata_value.to_sym, true)}] = #{val}"
						end
					end
				elsif command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop

					result = "#{compile_command(parts.join('.').to_sym, true)}[\"#{last_part}\"] = #{val}"
				else
					result = "#{command[1]} = #{val}"
				end

				result += "\nreturn @vars[:response] if !@vars[:response].nil?" if !nested

				return result
			when :return
				return "return #{compile_command(command[1], true)}"
			when :hash
				compiled_commands = []
				i = 1

				while !command[i].nil?
					compiled_commands.push({
						name: command[i][0],
						command: compile_command(command[i][1], true)
					})
					i += 1
				end

				return "{}" if compiled_commands.size == 0
				result = "{\n"

				for i in 0..compiled_commands.size - 1
					compiled_command = compiled_commands[i]
					result += "\"#{compiled_command[:name]}\" => #{compiled_command[:command]}"
					result += ", " if !compiled_commands[i + 1].nil?
					result += "\n"
				end

				result += "}"
				return result
			when :list
				compiled_commands = []
				i = 1

				while !command[i].nil?
					compiled_commands.push(compile_command(command[i], true))
					i += 1
				end

				return "[]" if compiled_commands.size == 0
				result = "[\n"

				for i in 0..compiled_commands.size - 1
					result += compiled_commands[i].to_s
					result += ", " if !compiled_commands[i + 1].nil?
					result += "\n"
				end

				result += "].compact"
				return result
			when :if
				result = "if (#{compile_command(command[1], true)})\n"
				result += "#{compile_command(command[2], nested)}\n"

				i = 3
				while !command[i].nil?
					if command[i] == :elseif
						result += "elsif #{compile_command(command[i + 1], true)}\n"
						result += "#{compile_command(command[i + 2], nested)}\n"
					elsif command[i] == :else
						result += "else\n#{compile_command(command[i + 1], nested)}\n"
					end

					i += 3
				end

				result += "end"
				return result
			when :for
				return nil if command[2] != :in
				varname = command[1]

				result = "#{compile_command(command[3], true)}.each do |#{varname}|\n"
				result += "next if #{varname}.nil?\n"
				result += compile_command(command[4])
				result += "end\n"

				return result
			when :continue
				return "next\n"
			when :break
				return "break\n"
			when :def
				name = command[1].to_s

				# Save that the function is defined
				@defined_functions.push(name)

				result = "def #{name}("
				i = 0

				command[2].each do |parameter|
					result += ", " if i != 0
					result += "#{parameter} = nil"
					i += 1
				end

				result += ")\n"
				result += "#{compile_command(command[3])}\nend\n"

				return result
			when :func
				name = command[1].to_s

				# Check if the function is defined
				if !@defined_functions.include?(name)
					# Try to get the function from the database
					function = ApiFunction.find_by(api_slot: @api_slot, name: name)
					return "" if function.nil?

					@defined_functions.push(name)
					@functions_to_define.push(function)
				end

				# Call the function
				result = "#{name}("

				i = 0
				command[2].each do |parameter|
					result += ", " if i != 0
					result += compile_command(parameter).to_s
					i += 1
				end

				result += ")"
				result += "\nreturn @vars[:response] if !@vars[:response].nil?" if !nested

				return result
			when :catch
				result = "begin\n"
				result += "#{compile_command(command[1])}\n"
				result += "rescue RuntimeError => e\n"
				result += "errors = JSON.parse(e.message)\n"
				result += "#{compile_command(command[2])}\nend\n"
				return result
			when :throw_errors
				errors = "[\n"
				i = 1

				while !command[i].nil?
					errors += "#{compile_command(command[i], true)},\n"
					i += 1
				end

				errors += "].to_json"
				return "raise RuntimeError, #{errors}"
			when :log
				return "puts #{compile_command(command[1], true)}"
			when :to_int
				return "#{compile_command(command[1], true)}.to_i"
			when :is_nil
				return "#{compile_command(command[1], true)}.nil?"
			when :parse_json
				return "_method_call('parse_json', json: #{compile_command(command[1], true)})"
			when :get_header
				return "@vars[:headers][#{compile_command(command[1], true)}]"
			when :get_param
				return "@vars[:params][#{compile_command(command[1], true)}]"
			when :get_params
				return "@vars[:params]"
			when :get_body
				return "_method_call('get_body')"
			when :get_error
				return "_method_call('get_error', code: #{compile_command(command[1], true)})"
			when :get_env
				return "@vars[:env][#{compile_command(command[1], true)}]"
			when :render_json
				status = 200
				status = compile_command(command[2], true) if !command[2].nil?

				return "_method_call('render_json',
					data: #{compile_command(command[1], true)},
					status: #{status}
				)"
			when :render_file
				status = 200
				status = compile_command(command[4], true) if command[4].nil?

				return "_method_call('render_file',
					data: #{compile_command(command[1], true)},
					type: #{compile_command(command[2], true)},
					filename: #{compile_command(command[3], true)},
					status: #{status}
				)"
			when :!
				return "!(#{compile_command(command[1], true)})"
			else
				# Command might be a method call
				case command[0].to_s
				when "#"
					# It's a comment. Ignore this command
					return ""
				when "User.get"
					return "_method_call('User.get',
						id: #{compile_command(command[1], true)}
					)"
				when "User.is_provider"
					return "_method_call('User.is_provider',
						user_id: #{compile_command(command[1], true)}
					)"
				when "Session.get"
					return "_method_call('Session.get',
						access_token: #{compile_command(command[1], true)}
					)"
				when "Table.get"
					return "_method_call('Table.get',
						id: #{compile_command(command[1], true)}
					)"
				when "Table.get_table_objects"
					return "_method_call('Table.get_table_objects',
						table_name: #{compile_command(command[1], true)},
						user_id: #{compile_command(command[2], true)}
					)"
				when "Table.get_table_object_uuids"
					return "_method_call('Table.get_table_object_uuids',
						table_name: #{compile_command(command[1], true)},
						user_id: #{compile_command(command[2], true)}
					)"
				when "TableObject.create"
					return "_method_call('TableObject.create',
						user_id: #{compile_command(command[1], true)},
						table_id: #{compile_command(command[2], true)},
						properties: #{compile_command(command[3], true)}
					)"
				when "TableObject.create_file"
					return "_method_call('TableObject.create_file',
						user_id: #{compile_command(command[1], true)},
						table_id: #{compile_command(command[2], true)},
						ext: #{compile_command(command[3], true)},
						type: #{compile_command(command[4], true)},
						file: #{compile_command(command[5], true)},
						properties: #{compile_command(command[6], true)}
					)"
				when "TableObject.get"
					return "_method_call('TableObject.get',
						uuid: #{compile_command(command[1], true)}
					)"
				when "TableObject.get_file"
					return "_method_call('TableObject.get_file',
						uuid: #{compile_command(command[1], true)}
					)"
				when "TableObject.update"
					return "_method_call('TableObject.update',
						uuid: #{compile_command(command[1], true)},
						properties: #{compile_command(command[2], true)}
					)"
				when "TableObject.update_file"
					return "_method_call('TableObject.update_file',
						uuid: #{compile_command(command[1], true)},
						ext: #{compile_command(command[2], true)},
						type: #{compile_command(command[3], true)},
						file: #{compile_command(command[4], true)}
					)"
				when "TableObject.set_price"
					return "_method_call('TableObject.set_price',
						uuid: #{compile_command(command[1], true)},
						price: #{compile_command(command[2], true)},
						currency: #{compile_command(command[3], true)}
					)"
				when "TableObject.get_price"
					return "_method_call('TableObject.get_price',
						uuid: #{compile_command(command[1], true)},
						currency: #{compile_command(command[2], true)}
					)"
				when "TableObject.get_cdn_url"
					return "_method_call('TableObject.get_cdn_url',
						uuid: #{compile_command(command[1], true)},
						params: #{compile_command(command[2], true)}
					)"
				when "TableObjectUserAccess.create"
					return "_method_call('TableObjectUserAccess.create',
						table_object_id: #{compile_command(command[1], true)},
						user_id: #{compile_command(command[2], true)},
						alias_table_name: #{compile_command(command[3], true)}
					)"
				when "Collection.add_table_object"
					return "_method_call('Collection.add_table_object',
						collection_name: #{compile_command(command[1], true)},
						table_object_id: #{compile_command(command[2], true)}
					)"
				when "Collection.remove_table_object"
					return "_method_call('Collection.remove_table_object',
						collection_name: #{compile_command(command[1], true)},
						table_object_id: #{compile_command(command[2], true)}
					)"
				when "Collection.get_table_objects"
					return "_method_call('Collection.get_table_objects',
						table_id: #{compile_command(command[1], true)},
						collection_name: #{compile_command(command[2], true)}
					)"
				when "Collection.get_table_object_uuids"
					return "_method_call('Collection.get_table_object_uuids',
						table_name: #{compile_command(command[1], true)},
						collection_name: #{compile_command(command[2], true)}
					)"
				when "TableObject.find_by_property"
					return "_method_call('TableObject.find_by_property',
						user_id: #{compile_command(command[1], true)},
						table_id: #{compile_command(command[2], true)},
						property_name: #{compile_command(command[3], true)},
						property_value: #{compile_command(command[4], true)},
						exact: #{compile_command(command[5], true)}
					)"
				when "Purchase.create"
					return "_method_call('Purchase.create',
						user_id: #{compile_command(command[1], true)},
						provider_name: #{compile_command(command[2], true)},
						provider_image: #{compile_command(command[3], true)},
						product_name: #{compile_command(command[4], true)},
						product_image: #{compile_command(command[5], true)},
						price: #{compile_command(command[6], true)},
						currency: #{compile_command(command[7], true)},
						table_objects: #{compile_command(command[8], true)}
					)"
				when "Purchase.get_table_object"
					return "_method_call('Purchase.get_table_object',
						purchase_id: #{compile_command(command[1], true)},
						user_id: #{compile_command(command[2], true)}
					)"
				when "Purchase.find_by_user_and_table_object"
					return "_method_call('Purchase.find_by_user_and_table_object',
						user_id: #{compile_command(command[1], true)},
						table_object_id: #{compile_command(command[2], true)}
					)"
				when "DateTime.now"
					return "_method_call('DateTime.now')"
				when "Math.round"
					return "_method_call('Math.round',
						var: #{compile_command(command[1], true)},
						rounding: #{compile_command(command[2], true)}
					)"
				when "Regex.match"
					return "_method_call('Regex.match',
						string: #{compile_command(command[1], true)},
						regex: #{compile_command(command[2], true)}
					)"
				when "Regex.check"
					return "_method_call('Regex.check',
						string: #{compile_command(command[1], true)},
						regex: #{compile_command(command[2], true)}
					)"
				when "Blurhash.encode"
					return "_method_call('Blurhash.encode',
						image_data: #{compile_command(command[1], true)}
					)"
				when "Image.get_details"
					return "_method_call('Image.get_details',
						image_data: #{compile_command(command[1], true)}
					)"
				end

				# Command might be an expression
				case command[1]
				when :==
					return "#{compile_command(command[0], true)} == #{compile_command(command[2], true)}"
				when :!=
					return "#{compile_command(command[0], true)} != #{compile_command(command[2], true)}"
				when :>
					return "#{compile_command(command[0], true)} > #{compile_command(command[2], true)}"
				when :<
					return "#{compile_command(command[0], true)} < #{compile_command(command[2], true)}"
				when :>=
					return "#{compile_command(command[0], true)} >= #{compile_command(command[2], true)}"
				when :<=
					return "#{compile_command(command[0], true)} <= #{compile_command(command[2], true)}"
				when :+, :-
					result = "(#{compile_command(command[0], true)})"
					i = 1

					while !command[i].nil?
						if command[i] == :-
							result += " - #{compile_command(command[i + 1], true)}"
						else
							result += " + #{compile_command(command[i + 1], true)}"
						end

						i += 2
					end

					return result
				when :*
					return "(#{compile_command(command[0], true)}) * (#{compile_command(command[2], true)})"
				when :/
					return "(#{compile_command(command[0], true)}) / (#{compile_command(command[2], true)})"
				when :%
					return "(#{compile_command(command[0], true)}) % (#{compile_command(command[2], true)})"
				when :and, :or
					result = "(#{compile_command(command[0], true)})"
					i = 1

					while !command[i].nil?
						if command[i] == :and
							result += " && (#{compile_command(command[i + 1], true)})"
						else
							result += " || (#{compile_command(command[i + 1], true)})"
						end

						i += 2
					end

					return result
				end

				if command[0].to_s.include?('.')
					parts = command[0].to_s.split('.')
					function_name = parts.pop
					complete_command = ""

					valid = [
						"push",
						"pop",
						"contains",
						"contains_all",
						"join",
						"select",
						"split"
					].include?(function_name)

					if valid
						# Change the function name if necessary
						if function_name == "contains"
							complete_command = "#{compile_command(parts.join('.').to_sym, true)}.include?"
						elsif function_name == "contains_all"
							return "_method_call('contains_all',
								original_array: #{compile_command(parts.join('.').to_sym, true)},
								comparing_array: #{compile_command(command[1], true)}
							)"
						elsif function_name == "select"
							return "#{parts.join('.')}[#{compile_command(command[1], true)}, #{compile_command(command[2], true)}]"
						else
							complete_command = "#{compile_command(parts.join('.').to_sym, true)}.#{function_name}"
						end

						# Get the parameters
						result = "#{complete_command}("

						i = 1
						while !command[i].nil?
							result += ", " if i != 1

							if command[i].is_a?(String)
								result += "\"#{command[i]}\""
							elsif command[i].is_a?(Array) && command[i].length == 1
								result += compile_command(command[i][0], true).to_s
							else
								result += compile_command(command[i], true).to_s
							end

							i += 1
						end

						result += ")"
						return result
					end

					return ""
				end

				# Treat the command like a series of commands
				code = ""
				command.each { |c| code += "#{compile_command(c, nested)}" }
				return code
			end
		elsif command.is_a?(String)
			return "\"#{command}\""
		elsif command.is_a?(Float)
			return command
		elsif command.is_a?(Regexp)
			return command.inspect
		elsif command.is_a?(NilClass)
			return "nil"
		elsif command.to_s.match /^[a-zA-Z0-9_-]{1,}\[[a-zA-Z0-9_\-\"\.#\[\]]{0,}\]$/
			matchdata = command.to_s.match /^(?<varname>[a-zA-Z0-9_-]{1,})\[(?<value>[a-zA-Z0-9_\-\"\.#\[\]]{0,})\]$/
			matchdata_varname = matchdata["varname"]
			matchdata_value = matchdata["value"]

			if matchdata_value[0] == "\"" && matchdata_value[-1] == "\""
				# value is a string
				return "#{matchdata_varname}[#{matchdata_value}]"
			else
				# value is an expression or var name
				return "#{matchdata_varname}[#{compile_command(matchdata_value.to_sym)}]"
			end
		elsif command.to_s.include?('.')
			parts = command.to_s.split('.')
			last_part = parts.pop
			index = nil

			if last_part.include?("#")
				last_part, index = last_part.split('#')
			end

			# Check if the last part is a method call
			valid = [
				"class",
				"length",
				"reverse",
				"upcase",
				"downcase",
				"escape",
				"unescape",
				"to_s",
				"to_i",
				"to_f",
				"round",
				"chars",
				"size",
				"keys",
				"values",
				"table_objects",
				"properties"
			].include?(last_part)

			if valid
				if last_part == "class"
					# Return the class as string
					return "#{command}.to_s"
				elsif last_part == "escape"
					return "CGI.escape(#{compile_command(parts.join('.').to_sym, true)})"
				elsif last_part == "unescape"
					return "CGI.unescape(#{compile_command(parts.join('.').to_sym, true)})"
				elsif last_part == "properties"
					# Return the TableObjectHolder directly
					return parts.join('.').to_sym
				elsif index.nil?
					return "#{compile_command(parts.join('.').to_sym, true)}.#{last_part}"
				else
					return "#{compile_command(parts.join('.').to_sym, true)}.#{last_part}[#{index}]"
				end
			elsif last_part.starts_with?("properties[")
				return "#{parts.join('.')}#{last_part[10..]}"
			end

			# The first part of the command is probably a variable / hash
			if index.nil?
				return "#{compile_command(parts.join('.').to_sym, true)}[\"#{last_part}\"]"
			else
				return "#{compile_command(parts.join('.').to_sym, true)}[#{last_part}[#{index}]]"
			end
		elsif command.to_s.include?('#')
			parts = command.to_s.split('#')
			last_part = parts.pop

			return "#{compile_command(parts.join('#').to_sym, true)}[#{last_part}]"
		else
			return command
		end
	end

	def compile_function_definition(function)
		result = "def #{function.name}("

		i = 0
		function.params.split(',').each do |parameter|
			result += ", " if i != 0
			result += "#{parameter} = nil"
			i += 1
		end

		result += ")\n"
		ast = @parser.parse_string(function.commands)

		ast.each do |element|
			result += "#{compile_command(element)}\n"
		end

		result += "end\n"
		return result
	end
end