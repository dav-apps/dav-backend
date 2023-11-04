class TablesController < ApplicationController
	def create_table
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
		ValidationService.raise_validation_errors(ValidationService.validate_name_validity(name))

		# Get the app
		app = App.find_by(id: app_id)
		ValidationService.raise_validation_errors(ValidationService.validate_app_existence(app))

		# Make sure the user is the dev of the app
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(app, session.user.dev))

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
		render_errors(e)
	end

	def get_table
		access_token = get_auth

		id = params["id"].to_i
		count = params["count"].to_i
		page = params["page"].to_i

		count = Constants::DEFAULT_TABLE_COUNT if count <= 0
		page = Constants::DEFAULT_TABLE_PAGE if page <= 0

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		
		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the table
		table = Table.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_table_existence(table))

		# Check if the table belongs to the app
		ValidationService.raise_validation_errors(ValidationService.validate_table_belongs_to_app(table, session.app))

		# Save that the user was active
		session.user.update_column(:last_active, Time.now)

		app_user = AppUser.find_by(user: session.user, app: session.app)
		app_user.update_column(:last_active, Time.now) if !app_user.nil?

		# Get the table objects of the user
		table_objects = Array.new
		TableObject.where(user_id: session.user.id, table_id: table.id).order(id: :ASC).each { |obj| table_objects.push(obj) }
		session.user.table_object_user_access.each { |access| table_objects.push(access.table_object) if access.table_alias == table.id }

		start = count * (page - 1)
		length = count > table_objects.count ? table_objects.count : count
		selected_table_objects = table_objects[start, length]

		pages = 1
		pages = table_objects.count % count == 0 ? table_objects.count / count : (table_objects.count / count) + 1 if table_objects.count > 0

		table_etag = UtilsService.get_table_etag(session.user, table)

		# Return the data
		result = {
			id: table.id,
			app_id: table.app_id,
			name: table.name,
			pages: pages,
			etag: table_etag,
			table_objects: Array.new
		}

		if !selected_table_objects.nil?
			selected_table_objects.each do |obj|
				# Generate the etag if the table object has none
				if obj.etag.nil?
					obj.etag = UtilsService.generate_table_object_etag(obj)
					obj.save
				end

				result[:table_objects].push({
					uuid: obj.uuid,
					etag: obj.etag
				})
			end
		end

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end