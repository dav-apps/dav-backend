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

		# Notify connected clients of the new table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 0,
			access_token_md5: (Digest::MD5.new << session.token).hexdigest
		)

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
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

		# Notify connected clients of the updated table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 1,
			access_token_md5: (Digest::MD5.new << session.token).hexdigest
		)

		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
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
			begin
				BlobOperationsService.delete_blob(table_object)
			rescue => e
			end

			# Update the used storage
			size_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME)
			UtilsService.update_used_storage(session.user, table_object.table.app, -size_property.value.to_i) if !size_property.nil?
		end

		# Delete the table object
		table_object.destroy!

		# Notify connected clients of the deleted table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 2,
			access_token_md5: (Digest::MD5.new << session.token).hexdigest
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
			blob = BlobOperationsService.upload_blob(table_object, request.body)
		rescue => e
			ValidationService.raise_unexpected_error
		end

		etag = blob.properties[:etag]
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

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Notify connected clients of the updated table object
		TableObjectUpdateChannel.broadcast_to(
			"#{session.user.id},#{session.app.id}",
			uuid: table_object.uuid,
			change: 1,
			access_token_md5: (Digest::MD5.new << session.token).hexdigest
		)

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
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

		# Delete the table object user access
		access.destroy!
		
		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end
end