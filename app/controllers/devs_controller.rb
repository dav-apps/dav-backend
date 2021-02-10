class DevsController < ApplicationController
	def get_dev
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Get the dev of the user
		dev = session.user.dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Return the data
		apps = Array.new

		dev.apps.each do |app|
			apps.push({
				id: app.id,
				name: app.name,
				description: app.description,
				published: app.published,
				web_link: app.web_link,
				google_play_link: app.google_play_link,
				microsoft_store_link: app.microsoft_store_link
			})
		end

		result = {
			id: dev.id,
			apps: apps
		}

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end