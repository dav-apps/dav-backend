class TableObjectsController < ApplicationController
	def create_table_object
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		uuid = body["uuid"]
		table_id = body["table_id"]
		file = body["file"]
		properties = body["properties"]

		# Validate missing fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_table_id_presence(table_id)
		])

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_uuid_type(uuid)) if !uuid.nil?
		validations.push(ValidationService.validate_table_id_type(table_id))
		validations.push(ValidationService.validate_file_type(file)) if !file.nil?
		validations.push(ValidationService.validate_properties_type(properties)) if !properties.nil?
		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Get the table
		table = Table.find_by(id: table_id)
		ValidationService.raise_validation_error(ValidationService.validate_table_existence(table))

		# Check if the table belongs to the app
		ValidationService.raise_validation_error(ValidationService.validate_table_belongs_to_app(table, app))

		# Create the table object
		table_object = TableObject.new(
			user: user,
			table: table,
			file: file.nil? ? false : file
		)

		if uuid.nil?
			table_object.uuid = SecureRandom.uuid
		else
			# Check if the uuid is already taken
			ValidationService.raise_validation_error(ValidationService.validate_uuid_availability(uuid))
			table_object.uuid = uuid
		end

		# Get the properties
		props = Hash.new
		if !properties.nil? && !table_object.file
			# Validate the properties
			properties.each do |key, value|
				ValidationService.raise_multiple_validation_errors([
					ValidationService.validate_property_name_type(key),
					ValidationService.validate_property_value_type(value)
				])
			end

			properties.each do |key, value|
				ValidationService.raise_multiple_validation_errors([
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
				ValidationService.raise_validation_error(ValidationService.validate_ext_type(ext))

				# Validate the length
				ValidationService.raise_validation_error(ValidationService.validate_ext_length(ext))

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
		user.update_column(:last_active, Time.now)

		# Save that the user uses the app
		app_user = AppUser.find_by(user: user, app: app)
		if app_user.nil?
			AppUser.create(
				user: user,
				app: app,
				last_active: Time.now
			)
		else
			app_user.update_column(:last_active, Time.now)
		end

		# Notify connected clients of the new table object
		TableObjectUpdateChannel.broadcast_to(
			"#{user.id},#{app.id}",
			uuid: table_object.uuid,
			session_id: session_id,
			change: 0
		)

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			properties: props
		}

		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def get_table_object
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		id = params["id"]

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Get the table object
		if id.include?('-')
			table_object = TableObject.find_by(uuid: id)
		else
			table_object = TableObject.find_by(id: id)
		end

		ValidationService.raise_validation_error(ValidationService.validate_table_object_existence(table_object))

		# Check if the user can access the table object
		user_access = TableObjectUserAccess.find_by(user: user, table_object: table_object)
		table_id = table_object.table_id

		if user_access.nil?
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(table_object, user))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_app(table_object, app))
		else
			table_id = user_access.table_alias
		end

		# Generate the etag if the table object has none
		if table_object.etag.nil?
			table_object.etag = UtilsService.generate_table_object_etag(table_object)
			table_object.save
		end

		# Save that the user was active
		user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: user, app: app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			properties: Hash.new
		}

		property_types = table_object.table.table_property_types
		table_object.table_object_properties.each do |property|
			result[:properties][property.name] = UtilsService.convert_value_to_data_type(property.value, UtilsService.find_data_type(property_types, property.name))
		end

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def update_table_object
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))
		payload = ValidationService.validate_jwt(jwt, session_id)

		id = params["id"]

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		properties = body["properties"]

		# Validate missing fields
		ValidationService.raise_validation_error(ValidationService.validate_properties_presence(properties))

		# Validate the type of the field
		ValidationService.raise_validation_error(ValidationService.validate_properties_type(properties))

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Get the table object
		if id.include?('-')
			table_object = TableObject.find_by(uuid: id)
		else
			table_object = TableObject.find_by(id: id)
		end

		ValidationService.raise_validation_error(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(table_object, user))
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_app(table_object, app))

		# Check if the table object is a file
		ValidationService.raise_validation_error(ValidationService.validate_table_object_is_not_file(table_object))

		# Validate the properties
		properties.each do |key, value|
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_property_name_type(key),
				ValidationService.validate_property_value_type(value)
			])
		end

		properties.each do |key, value|
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_property_name_length(key),
				ValidationService.validate_property_value_length(value)
			])
		end

		properties.each do |key, value|
			# Try to find the property
			prop = TableObjectProperty.find_by(table_object: table_object, name: key)

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

		# Update the etag
		table_object.etag = UtilsService.generate_table_object_etag(table_object)
		ValidationService.raise_unexpected_error(!table_object.save)

		# Save that the user was active
		user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Notify connected clients of the updated table object
		TableObjectUpdateChannel.broadcast_to(
			"#{user.id},#{app.id}",
			uuid: table_object.uuid,
			session_id: session_id,
			change: 1
		)

		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			properties: Hash.new
		}

		# Get all properties of the table object
		property_types = table_object.table.table_property_types
		table_object.table_object_properties.each do |property|
			result[:properties][property.name] = UtilsService.convert_value_to_data_type(property.value, UtilsService.find_data_type(property_types, property.name))
		end

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def delete_table_object
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		id = params["id"]

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Get the table object
		if id.include?('-')
			table_object = TableObject.find_by(uuid: id)
		else
			table_object = TableObject.find_by(id: id)
		end

		ValidationService.raise_validation_error(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(table_object, user))
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_app(table_object, app))

		# Save that the user was active
		user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Delete the file if there is one
		if table_object.file
			BlobOperationsService.delete_blob(table_object)

			# Update the used storage
			size_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME)
			UtilsService.update_used_storage(user, table_object.table.app, -size_property.value.to_i) if !size_property.nil?
		end

		# Delete the table object
		table_object.destroy!

		# Notify connected clients of the deleted table object
		TableObjectUpdateChannel.broadcast_to(
			"#{user.id},#{app.id}",
			uuid: table_object.uuid,
			session_id: session_id,
			change: 2
		)

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def set_table_object_file
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		content_type = get_content_type
		ValidationService.raise_validation_error(ValidationService.validate_content_type_supported(content_type))
		payload = ValidationService.validate_jwt(jwt, session_id)

		id = params["id"]

		# Validate the payload data
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Get the table object
		if id.include?('-')
			table_object = TableObject.find_by(uuid: id)
		else
			table_object = TableObject.find_by(id: id)
		end

		ValidationService.raise_validation_error(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(table_object, user))
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_app(table_object, app))

		# Check if the table object is a file
		ValidationService.raise_validation_error(ValidationService.validate_table_object_is_file(table_object))

		# Get the size property
		size_prop = TableObjectProperty.find_by(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME)
		old_file_size = size_prop.nil? ? 0 : size_prop.value.to_i

		# Check if the user has enough free storage
		file_size = UtilsService.get_file_size(request.body)
		free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage
		file_size_diff = file_size - old_file_size
		ValidationService.raise_validation_error(ValidationService.validate_sufficient_storage(free_storage, file_size_diff))

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
		UtilsService.update_used_storage(user, app, file_size_diff)

		# Update the etag of the table object
		table_object.etag = UtilsService.generate_table_object_etag(table_object)
		ValidationService.raise_unexpected_error(!table_object.save)

		# Save that the user was active
		user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Notify connected clients of the updated table object
		TableObjectUpdateChannel.broadcast_to(
			"#{user.id},#{app.id}",
			uuid: table_object.uuid,
			session_id: session_id,
			change: 1
		)

		# Return the data
		result = {
			id: table_object.id,
			user_id: table_object.user_id,
			table_id: table_object.table_id,
			uuid: table_object.uuid,
			file: table_object.file,
			etag: table_object.etag,
			properties: Hash.new
		}

		# Get all properties of the table object
		property_types = table_object.table.table_property_types
		table_object.table_object_properties.each do |property|
			result[:properties][property.name] = UtilsService.convert_value_to_data_type(property.value, UtilsService.find_data_type(property_types, property.name))
		end

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def get_table_object_file
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		id = params["id"]

		# Validate the payload data
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Get the table object
		if id.include?('-')
			table_object = TableObject.find_by(uuid: id)
		else
			table_object = TableObject.find_by(id: id)
		end

		ValidationService.raise_validation_error(ValidationService.validate_table_object_existence(table_object))

		# Check if the user can access the table object
		user_access = TableObjectUserAccess.find_by(user: user, table_object: table_object)

		if user_access.nil?
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(table_object, user))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_app(table_object, app))
		end

		# Check if the table object is a file
		ValidationService.raise_validation_error(ValidationService.validate_table_object_is_file(table_object))

		# Get the file
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
		user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: user, app: table_object.table.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Return the data
		response.headers["Content-Length"] = content.nil? ? 0 : content.size.to_s
		send_data(content, status: 200, type: type, filename: filename)
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end