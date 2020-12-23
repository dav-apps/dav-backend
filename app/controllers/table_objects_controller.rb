class TableObjectsController < ApplicationController
	def create_table_object
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))
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

		# Get the table
		table = Table.find_by(id: table_id)
		ValidationService.raise_validation_error(ValidationService.validate_table_existence(table))

		# Check if the user can create a table object for the table with this session
		session = Session.find_by(id: session_id)
		ValidationService.raise_validation_error(ValidationService.validate_session_belongs_to_app(session, table.app))

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
		end

		# Calculate the etag of the table object
		table_object.etag = UtilsService.generate_table_object_etag(table_object)

		# Save the table object
		ValidationService.raise_unexpected_error(!table_object.save)

		# Save that the user was active
		user.update_column(:last_active, Time.now)

		# Save that the user uses the app
		app_user = AppUser.find_by(user: user, app: table.app)
		if app_user.nil?
			AppUser.create(
				user: user,
				app: table.app,
				last_active: Time.now
			)
		else
			app_user.update_column(:last_active, Time.now)
		end

		# Notify connected clients of the new table object
		# TODO

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

			# Check if the user can access the table object with this session
			session = Session.find_by(id: session_id)
			ValidationService.raise_validation_error(ValidationService.validate_session_belongs_to_app(session, table_object.table.app))
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

		app_user = AppUser.find_by(user: user, app: table_object.table.app)
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
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))
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

		# Get the table object
		if id.include?('-')
			table_object = TableObject.find_by(uuid: id)
		else
			table_object = TableObject.find_by(id: id)
		end

		ValidationService.raise_validation_error(ValidationService.validate_table_object_existence(table_object))
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(table_object, user))

		# Check if the user can access the table object with this session
		session = Session.find_by(id: session_id)
		ValidationService.raise_validation_error(ValidationService.validate_session_belongs_to_app(session, table_object.table.app))

		# Check if the table object is a file
		ValidationService.raise_validation_error(ValidationService.validate_table_object_is_file(table_object))

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
end