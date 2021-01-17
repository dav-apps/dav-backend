class AppsController < ApplicationController
	def create_app
		jwt, session_id = get_jwt

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(jwt))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Make sure this was called from the website
		ValidationService.raise_validation_error(ValidationService.validate_app_is_dav_app(app))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		name = body["name"]
		description = body["description"]

		# Validate missing fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_name_presence(name),
			ValidationService.validate_description_presence(description)
		])

		# Validate the types of the fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_name_type(name),
			ValidationService.validate_description_type(description)
		])

		# Validate the length of the fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_name_length(name),
			ValidationService.validate_description_length(description)
		])

		# Get the dev of the user
		dev = user.dev
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		# Create the app
		app = App.new(
			dev: dev,
			name: name,
			description: description
		)
		ValidationService.raise_unexpected_error(!app.save)

		# Return the data
		result = {
			id: app.id,
			dev_id: app.dev_id,
			name: app.name,
			description: app.description,
			published: app.published,
			web_link: app.web_link,
			google_play_link: app.google_play_link,
			microsoft_store_link: app.microsoft_store_link
		}

		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
	
	def get_apps
		# Collect and return the data
		apps = Array.new

		App.where(published: true).each do |app|
			apps.push({
				id: app.id,
				dev_id: app.dev_id,
				name: app.name,
				description: app.description,
				published: app.published,
				web_link: app.web_link,
				google_play_link: app.google_play_link,
				microsoft_store_link: app.microsoft_store_link
			})
		end

		result = {
			apps: apps
		}

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def get_app
		jwt, session_id = get_jwt
		id = params["id"]

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the payload data
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Make sure this was called from the website
		ValidationService.raise_validation_error(ValidationService.validate_app_is_dav_app(app))

		# Get the app
		app = App.find_by(id: id)
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Check if the app belongs to the dev of the user
		ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, user.dev))

		# Return the data
		tables = Array.new
		app.tables.each do |table|
			tables.push({
				id: table.id,
				name: table.name
			})
		end

		apis = Array.new
		app.apis.each do |api|
			apis.push({
				id: api.id,
				name: api.name
			})
		end

		result = {
			id: app.id,
			dev_id: app.dev_id,
			name: app.name,
			description: app.description,
			published: app.published,
			web_link: app.web_link,
			google_play_link: app.google_play_link,
			microsoft_store_link: app.microsoft_store_link,
			tables: tables,
			apis: apis
		}

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def update_app
		jwt, session_id = get_jwt
		id = params["id"]

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(jwt))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the payload data
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Make sure this was called from the website
		ValidationService.raise_validation_error(ValidationService.validate_app_is_dav_app(app))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		name = body["name"]
		description = body["description"]
		published = body["published"]
		web_link = body["web_link"]
		google_play_link = body["google_play_link"]
		microsoft_store_link = body["microsoft_store_link"]

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_name_type(name)) if !name.nil?
		validations.push(ValidationService.validate_description_type(description)) if !description.nil?
		validations.push(ValidationService.validate_published_type(published)) if !published.nil?
		validations.push(ValidationService.validate_web_link_type(web_link)) if !web_link.nil?
		validations.push(ValidationService.validate_google_play_link_type(google_play_link)) if !google_play_link.nil?
		validations.push(ValidationService.validate_microsoft_store_link_type(microsoft_store_link)) if !microsoft_store_link.nil?
		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the length of the fields
		validations = Array.new
		validations.push(ValidationService.validate_name_length(name)) if !name.nil?
		validations.push(ValidationService.validate_description_length(description)) if !description.nil?
		validations.push(ValidationService.validate_web_link_length(web_link)) if !web_link.nil?
		validations.push(ValidationService.validate_google_play_link_length(google_play_link)) if !google_play_link.nil?
		validations.push(ValidationService.validate_microsoft_store_link_length(microsoft_store_link)) if !microsoft_store_link.nil?
		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the links
		validations = Array.new
		validations.push(ValidationService.validate_web_link_validity(web_link)) if !web_link.nil?
		validations.push(ValidationService.validate_google_play_link_validity(google_play_link)) if !google_play_link.nil?
		validations.push(ValidationService.validate_microsoft_store_link_validity(microsoft_store_link)) if !microsoft_store_link.nil?
		ValidationService.raise_multiple_validation_errors(validations)

		# Get the app
		app = App.find_by(id: id)
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Make sure the user is the dev of the app
		ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, user.dev))

		# Update the app
		app.name = name if !name.nil?
		app.description = description if !description.nil?
		app.published = published if !published.nil?
		app.web_link = web_link.length == 0 ? nil : web_link if !web_link.nil?
		app.google_play_link = google_play_link.length == 0 ? nil : google_play_link if !google_play_link.nil?
		app.microsoft_store_link = microsoft_store_link.length == 0 ? nil : microsoft_store_link if !microsoft_store_link.nil?
		ValidationService.raise_unexpected_error(!app.save)

		# Return the data
		result = {
			id: app.id,
			dev_id: app.dev_id,
			name: app.name,
			description: app.description,
			published: app.published,
			web_link: app.web_link,
			google_play_link: app.google_play_link,
			microsoft_store_link: app.microsoft_store_link
		}

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end