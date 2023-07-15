class TableObjectsController < ApplicationController
	def create_table_object
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))
		
		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		uuid = body["uuid"]
		table_id = body["table_id"]
		file = body["file"]
		properties = body["properties"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_table_id_presence(table_id)
		])

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_uuid_type(uuid)) if !uuid.nil?
		validations.push(ValidationService.validate_table_id_type(table_id))
		validations.push(ValidationService.validate_file_type(file)) if !file.nil?
		validations.push(ValidationService.validate_properties_type(properties)) if !properties.nil?
		ValidationService.raise_validation_errors(validations)

		# Get the table
		table = Table.find_by(id: table_id)
		ValidationService.raise_validation_errors(ValidationService.validate_table_existence(table))

		# Check if the table belongs to the app
		ValidationService.raise_validation_errors(ValidationService.validate_table_belongs_to_app(table, session.app))

		# Create the table object
		table_object = TableObject.new(
			user: session.user,
			table: table,
			file: file.nil? ? false : file
		)

		if uuid.nil?
			table_object.uuid = SecureRandom.uuid
		else
			# Check if the uuid is already taken
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_uuid_availability(uuid))
			table_object.uuid = uuid
		end

		# Get the properties
		props = Hash.new
		if !properties.nil? && !table_object.file
			# Validate the properties
			properties.each do |key, value|
				ValidationService.raise_validation_errors([
					ValidationService.validate_property_name_type(key),
					ValidationService.validate_property_value_type(value)
				])
			end

			properties.each do |key, value|
				ValidationService.raise_validation_errors([
					ValidationService.validate_property_name_length(key),
					ValidationService.validate_property_value_length(value)
				])
			end

			properties.each do |key, value|
				next if value.nil?
				UtilsService.create_property_type(table, key, value)

				prop = TableObjectProperty.new(
					table_object: table_object,
					name: key,
					value: value.to_s
				)
				ValidationService.raise_unexpected_error(!prop.save)

				props[key] = value
			end
		elsif !properties.nil? && table_object.file
			# Take the ext property
			ext = properties["ext"]

			if !ext.nil?
				# Validate the type
				ValidationService.raise_validation_errors(ValidationService.validate_ext_type(ext))

				# Validate the length
				ValidationService.raise_validation_errors(ValidationService.validate_ext_length(ext))

				ext_prop = TableObjectProperty.new(
					table_object: table_object,
					name: Constants::EXT_PROPERTY_NAME,
					value: ext
				)
				ValidationService.raise_unexpected_error(!ext_prop.save)
				
				props[Constants::EXT_PROPERTY_NAME] = ext
			end
		end

		# Calculate the etag of the table object
		table_object.etag = UtilsService.generate_table_object_etag(table_object)

		# Save the table object
		ValidationService.raise_unexpected_error(!table_object.save)

		# Save the table object in redis
		UtilsService.save_table_object_in_redis(table_object)

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		# Save that the user uses the app
		app_user = AppUser.find_by(user: session.user, app: session.app)
		if app_user.nil?
			AppUser.create(
				user: session.user,
				app: session.app,
				last_active: Time.now
			)
		else
			app_user.update_column(:last_active, Time.now)
		end

		# Update the TableEtag
		table_etag = UtilsService.update_table_etag(session.user, table)

		# Notify connected clients of the new table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 0,
			access_token_md5: UtilsService.generate_md5(session.token)
		)

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			table_etag: table_etag,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			belongs_to_user: true,
			purchase: nil,
			properties: props
		}

		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end

	def get_table_object
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		
		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)

		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))

		# Check if the user can access the table object
		user_access = TableObjectUserAccess.find_by(user: session.user, table_object: table_object)
		table_id = table_object.table_id
		belongs_to_user = true
		purchase_uuid = nil

		if user_access.nil?
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_user(table_object, session.user))
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))
		else
			table_id = user_access.table_alias if !user_access.table_alias.nil?
			belongs_to_user = false
			purchase = table_object.purchases.find_by(user: session.user, completed: true)
			purchase_uuid = purchase.nil? ? nil : purchase.uuid
		end

		# Generate the etag if the table object has none
		if table_object.etag.nil?
			table_object.etag = UtilsService.generate_table_object_etag(table_object)
			table_object.save
		end

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: session.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			belongs_to_user: belongs_to_user,
			purchase: purchase_uuid,
			properties: Hash.new
		}

		property_types = table_object.table.table_property_types
		table_object.table_object_properties.each do |property|
			result[:properties][property.name] = UtilsService.convert_value_to_data_type(property.value, UtilsService.find_data_type(property_types, property.name))
		end

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def update_table_object
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))
		
		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		properties = body["properties"]

		# Validate missing fields
		ValidationService.raise_validation_errors(ValidationService.validate_properties_presence(properties))

		# Validate the type of the field
		ValidationService.raise_validation_errors(ValidationService.validate_properties_type(properties))

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)

		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_user(table_object, session.user))
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))

		# Check if the table object is a file
		if table_object.file
			# Take the ext property
			ext = properties["ext"]

			if !ext.nil?
				# Validate the type
				ValidationService.raise_validation_errors(ValidationService.validate_ext_type(ext))

				# Validate the length
				ValidationService.raise_validation_errors(ValidationService.validate_ext_length(ext))

				ext_prop = TableObjectProperty.find_by(table_object: table_object, name: Constants::EXT_PROPERTY_NAME)

				if ext_prop.nil?
					# Create the property
					ext_prop = TableObjectProperty.new(
						table_object: table_object,
						name: Constants::EXT_PROPERTY_NAME,
						value: ext
					)
				else
					# Update the property
					ext_prop.value = ext
				end

				ValidationService.raise_unexpected_error(!ext_prop.save)
			end
		else
			# Validate the properties
			properties.each do |key, value|
				ValidationService.raise_validation_errors([
					ValidationService.validate_property_name_type(key),
					ValidationService.validate_property_value_type(value)
				])
			end

			properties.each do |key, value|
				ValidationService.raise_validation_errors([
					ValidationService.validate_property_name_length(key),
					ValidationService.validate_property_value_length(value)
				])
			end

			properties.each do |key, value|
				# Try to find the property
				prop = TableObjectProperty.find_by(table_object: table_object, name: key)
				value = nil if value.to_s.length == 0

				if prop.nil? && !value.nil?
					# Create a new property
					UtilsService.create_property_type(table_object.table, key, value)

					prop = TableObjectProperty.new(
						table_object: table_object,
						name: key,
						value: value.to_s
					)
					ValidationService.raise_unexpected_error(!prop.save)
				elsif !prop.nil? && value.nil?
					# Delete the property
					prop.destroy!
				elsif !prop.nil? && !value.nil?
					# Update the property
					prop.value = value
					ValidationService.raise_unexpected_error(!prop.save)
				end
			end
		end

		# Update the etag
		table_object.etag = UtilsService.generate_table_object_etag(table_object)
		ValidationService.raise_unexpected_error(!table_object.save)

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Update the TableEtag
		table_etag = UtilsService.update_table_etag(session.user, table_object.table)

		# Update the table object in redis
		UtilsService.save_table_object_in_redis(table_object)

		# Notify connected clients of the updated table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 1,
			access_token_md5: UtilsService.generate_md5(session.token)
		)

		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			table_etag: table_etag,
			belongs_to_user: true,
			purchase: nil,
			properties: Hash.new
		}

		# Get all properties of the table object
		property_types = table_object.table.table_property_types
		table_object.table_object_properties.each do |property|
			result[:properties][property.name] = UtilsService.convert_value_to_data_type(property.value, UtilsService.find_data_type(property_types, property.name))
		end

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def delete_table_object
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)

		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_user(table_object, session.user))
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Delete the file if there is one
		if table_object.file
			BlobOperationsService.delete_blob(table_object)

			# Update the used storage
			size_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME)
			UtilsService.update_used_storage(session.user, table_object.table.app, -size_property.value.to_i) if !size_property.nil?
		end

		# Delete the table object
		table_object.destroy!

		# Remove the table object from redis
		UtilsService.remove_table_object_from_redis(table_object)

		# Update the TableEtag
		UtilsService.update_table_etag(session.user, table_object.table)

		# Notify connected clients of the deleted table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 2,
			access_token_md5: UtilsService.generate_md5(session.token)
		)

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	def set_table_object_file
		access_token = get_auth
		content_type = get_content_type
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_supported(content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)

		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_user(table_object, session.user))
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))

		# Check if the table object is a file
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_is_file(table_object))

		# Get the size property
		size_prop = TableObjectProperty.find_by(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME)
		old_file_size = size_prop.nil? ? 0 : size_prop.value.to_i

		# Check if the user has enough free storage
		file_size = UtilsService.get_file_size(request.body)
		free_storage = UtilsService.get_total_storage(session.user.plan, session.user.confirmed) - session.user.used_storage
		file_size_diff = file_size - old_file_size
		ValidationService.raise_validation_errors(ValidationService.validate_sufficient_storage(free_storage, file_size_diff))

		# Upload the file
		begin
			upload_result = BlobOperationsService.upload_blob(table_object, request.body, content_type)
		rescue => e
			ValidationService.raise_unexpected_error
		end

		etag = upload_result.etag
		etag = etag[1...etag.size - 1]

		# Set the size property
		if size_prop.nil?
			# Create the property
			size_prop = TableObjectProperty.new(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME, value: file_size)
		else
			# Update the property
			size_prop.value = file_size
		end
		ValidationService.raise_unexpected_error(!size_prop.save)

		# Set the type property
		type_prop = TableObjectProperty.find_by(table_object: table_object, name: Constants::TYPE_PROPERTY_NAME)
		if type_prop.nil?
			# Create the property
			type_prop = TableObjectProperty.new(table_object: table_object, name: Constants::TYPE_PROPERTY_NAME, value: content_type)
		else
			# Update the property
			type_prop.value = content_type
		end
		ValidationService.raise_unexpected_error(!type_prop.save)

		# Set the etag property
		etag_prop = TableObjectProperty.find_by(table_object: table_object, name: Constants::ETAG_PROPERTY_NAME)
		if etag_prop.nil?
			# Create the property
			etag_prop = TableObjectProperty.new(table_object: table_object, name: Constants::ETAG_PROPERTY_NAME, value: etag)
		else
			# Update the property
			etag_prop.value = etag
		end
		ValidationService.raise_unexpected_error(!etag_prop.save)

		# Save the new used storage
		UtilsService.update_used_storage(session.user, session.app, file_size_diff)

		# Update the etag of the table object
		table_object.etag = UtilsService.generate_table_object_etag(table_object)
		ValidationService.raise_unexpected_error(!table_object.save)

		# Update the table object in redis
		UtilsService.save_table_object_in_redis(table_object)

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Update the TableEtag
		table_etag = UtilsService.update_table_etag(session.user, table_object.table)

		# Notify connected clients of the updated table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 1,
			access_token_md5: UtilsService.generate_md5(session.token)
		)

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			table_etag: table_etag,
			belongs_to_user: true,
			purchase: nil,
			properties: Hash.new
		}

		# Get all properties of the table object
		property_types = table_object.table.table_property_types
		table_object.table_object_properties.each do |property|
			result[:properties][property.name] = UtilsService.convert_value_to_data_type(property.value, UtilsService.find_data_type(property_types, property.name))
		end

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def get_table_object_file
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		
		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)

		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))

		# Check if the user can access the table object
		user_access = TableObjectUserAccess.find_by(user: session.user, table_object: table_object)

		if user_access.nil?
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_user(table_object, session.user))
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))
		end

		# Check if the table object is a file
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_is_file(table_object))

		# Download the file
		begin
			blob, content = BlobOperationsService.download_blob(table_object)
		rescue => e
			ValidationService.raise_table_object_has_no_file
		end

		ValidationService.raise_table_object_has_no_file if content.nil? || content.length == 0

		# Get the ext and type properties
		ext_prop = TableObjectProperty.find_by(table_object: table_object, name: Constants::EXT_PROPERTY_NAME)
		ext = ext_prop.nil? ? nil : ext_prop.value

		type_prop = TableObjectProperty.find_by(table_object: table_object, name: Constants::TYPE_PROPERTY_NAME)
		type = type_prop.nil? ? "application/octet-stream" : type_prop.value

		filename = table_object.id.to_s
		filename += ".#{ext}" if !ext.nil?

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Return the data
		response.headers["Content-Length"] = content.nil? ? 0 : content.size.to_s
		send_data(content, status: 200, type: type, filename: filename)
	rescue RuntimeError => e
		render_errors(e)
	end

	def remove_table_object
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)

		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))

		# Check if the table object user access exists
		access = TableObjectUserAccess.find_by(user: session.user, table_object: table_object)
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_user_access_existence(access))

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: session.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Update the TableEtag
		UtilsService.update_table_etag(session.user, table_object.table)

		# Delete the table object user access
		access.destroy!

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	# v2
	def list_table_objects
		caching = params[:caching].nil? || params[:caching] == "true"
		limit = params[:limit].to_i
		offset = params[:offset].to_i
		collection_name = params[:collection_name]
		table_name = params[:table_name]
		user_id = params[:user_id].to_i
		property_name = params[:property_name]
		property_value = params[:property_value]
		exact = params[:exact] == "true"
		table = nil
		user = nil

		limit = 10 if limit <= 0
		offset = 0 if offset < 0

		if caching
			# Try to get the response from redis
			cache_key = "list_table_objects;limit:#{limit};offset:#{offset};collection_name:#{collection_name};table_name:#{table_name};user_id:#{user_id}"
			cache_data = UtilsService.redis.get(cache_key)

			if !cache_data.nil?
				# Render the cache response
				render json: cache_data, status: 200
				return
			end
		end

		if !collection_name.nil?
			collection = Collection.find_by(name: collection_name)
		end

		if !table_name.nil?
			table = Table.find_by(name: table_name, app_id: 6)
		end

		if user_id != 0
			user = User.find(user_id)
		end

		if !property_name.nil? && !property_value.nil?
			table_objects_hash = Hash.new
			property_keys = get_table_object_properties(
				user_id,
				table.id,
				property_name
			)

			if exact
				property_keys.each do |key|
					value = convert_value_to_data_type(UtilsService.redis.get(key), key.split(':').last.to_i)

					if value == property_value
						# Get the table object id from the key
						table_object_uuid = key.split(':')[3]
						next if table_objects_hash.include?(table_object_uuid)

						# Add the table object to the list of objects
						obj = TableObject.find_by(uuid: table_object_uuid)
						next if obj.nil?

						table_objects_hash[table_object_uuid] = obj
					end
				end
			else
				property_keys.each do |key|
					value = convert_value_to_data_type(UtilsService.redis.get(key), key.split(':').last.to_i)

					if value.include?(property_value)
						# Get the table object id from the key
						table_object_uuid = key.split(':')[3]
						next if table_objects_hash.include?(table_object_uuid)

						# Add the table object to the list of objects
						obj = TableObject.find_by(uuid: table_object_uuid)
						next if obj.nil?

						table_objects_hash[table_object_uuid] = obj
					end
				end
			end

			table_objects = table_objects_hash.values.to_a
		else
			# Find the table objects
			if !collection.nil?
				table_objects = collection.table_objects.limit(limit).offset(offset)
			elsif !table.nil? && user.nil?
				table_objects = TableObject.where(table: table).limit(limit).offset(offset)
			elsif table.nil? && !user.nil?
				table_objects = TableObject.where(user: user).limit(limit).offset(offset)
			elsif !table.nil? && !user.nil?
				table_objects = TableObject.where(user: user, table: table).limit(limit).offset(offset)
			else
				table_objects = []
			end
		end

		table_objects_array = Array.new

		table_objects.each do |obj|
			props_hash = Hash.new

			obj.table_object_properties.each do |prop|
				property_types = obj.table.table_property_types
				props_hash[prop.name] = UtilsService.convert_value_to_data_type(prop.value, UtilsService.find_data_type(property_types, prop.name))
			end

			table_objects_array.push({
				uuid: obj.uuid,
				user_id: obj.user_id,
				table_id: obj.table_id,
				properties: props_hash
			})
		end

		result = {
			table_objects: table_objects_array
		}

		# Save the response in redis
		UtilsService.redis.set(cache_key, result.to_json)
		UtilsService.redis.expire(cache_key, 1.day.to_i)

		render json: result, status: 200
	end

	def retrieve_table_object
		uuid = params[:uuid]
		caching = params[:caching].nil? || params[:caching] == "true"

		# Try to get the table object from redis
		cache_key = "table_object:#{uuid}"
		obj_json = caching ? UtilsService.redis.get(cache_key) : nil

		if obj_json.nil?
			# Get the table object
			obj = TableObject.find_by(uuid: uuid)

			if obj.nil?
				status = 404
				result = {
					error: "table_object_does_not_exist"
				}
			else
				status = 200
				props_hash = Hash.new

				obj.table_object_properties.each do |prop|
					property_types = obj.table.table_property_types
					props_hash[prop.name] = UtilsService.convert_value_to_data_type(prop.value, UtilsService.find_data_type(property_types, prop.name))
				end

				# Save the table object in redis
				obj_data = {
					'id' => obj.id,
					'user_id' => obj.user_id,
					'table_id' => obj.table_id,
					'file' => obj.file,
					'etag' => obj.etag,
					'properties' => props_hash
				}

				UtilsService.redis.set(cache_key, obj_data.to_json)
				UtilsService.redis.expire(cache_key, 14.days.to_i)

				result = {
					uuid: obj.uuid,
					user_id: obj.user_id,
					table_id: obj.table_id,
					properties: props_hash
				}
			end
		else
			obj_data = JSON.parse(obj_json)

			result = {
				uuid: uuid,
				user_id: obj_data["user_id"],
				table_id: obj_data["table_id"],
				properties: obj_data["properties"]
			}
		end

		render json: result, status: status
	end

	private
	def get_table_object_properties(user_id, table_id, property_name)
		user_id_str = user_id <= 0 ? "*" : user_id.to_s
		table_id_str = table_id <= 0 ? "*" : table_id.to_s
		property_name = "*" if property_name.nil?

		return UtilsService.redis.keys("table_object_property:#{user_id_str}:#{table_id_str}:*:#{property_name}:*")
	end

	def convert_value_to_data_type(value, data_type)
		return value == "true" if data_type == 1
		return Integer value rescue value if data_type == 2
		return Float value rescue value if data_type == 3
		return value
	end
end