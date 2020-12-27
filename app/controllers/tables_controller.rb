class TablesController < ApplicationController
	def create_table
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))

		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		# Make sure this was called from the website
		ValidationService.raise_validation_error(ValidationService.validate_app_is_dav_app(payload[:app_id]))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		app_id = body["app_id"]
		name = body["name"]

		# Validate missing fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_app_id_presence(app_id),
			ValidationService.validate_name_presence(name)
		])

		# Validate the types of the fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_app_id_type(app_id),
			ValidationService.validate_name_type(name)
		])

		# Get the app
		app = App.find_by(id: app_id)
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Make sure the user is the dev of the app
		ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, user.dev))

		# Validate the name
		ValidationService.raise_validation_error(ValidationService.validate_name_length(name))
		ValidationService.raise_validation_error(ValidationService.validate_name_validity(name))

		# Create the table
		table = Table.new(
			app: app,
			name: name
		)
		ValidationService.raise_unexpected_error(!table.save)

		# Return the new table
		result = {
			id: table.id,
			app_id: table.app_id,
			name: table.name
		}
		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def get_table
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))

		id = params["id"].to_i
		count = params["count"].to_i
		page = params["page"].to_i

		count = Constants::DEFAULT_TABLE_COUNT if count <= 0
		page = Constants::DEFAULT_TABLE_PAGE if page <= 0

		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Get the table
		table = Table.find_by(id: id)
		ValidationService.raise_validation_error(ValidationService.validate_table_existence(table))

		# Check if the table belongs to the app
		ValidationService.raise_validation_error(ValidationService.validate_table_belongs_to_app(table, app))

		# Save that the user was active
		user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: user, app: app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Get the table objects of the user
		table_objects = Array.new
		TableObject.where(user_id: user.id, table_id: table.id).each { |obj| table_objects.push(obj) }
		user.table_object_user_access.each { |access| table_objects.push(access.table_object) if access.table_alias == table.id }

		start = count * (page - 1)
		length = count > table_objects.count ? table_objects.count : count
		selected_table_objects = table_objects[start, length]

		pages = 1
		pages = table_objects.count % count == 0 ? table_objects.count / count : (table_objects.count / count) + 1 if table_objects.count > 0

		# Return the data
		result = {
			id: table.id,
			app_id: table.app_id,
			name: table.name,
			pages: pages,
			table_objects: Array.new
		}

		selected_table_objects.each do |obj|
			# Generate the etag if the table object has none
			if obj.etag.nil?
				obj.etag = UtilsService.generate_table_object_etag(obj)
				obj.save
			end

			result[:table_objects].push({
				id: obj.id,
				uuid: obj.uuid,
				etag: obj.etag
			})
		end

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end