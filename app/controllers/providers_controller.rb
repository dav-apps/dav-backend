class ProvidersController < ApplicationController
	def create_provider
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		country = body["country"]

		ValidationService.raise_validation_errors(ValidationService.validate_country_presence(country))
		ValidationService.raise_validation_errors(ValidationService.validate_country_type(country))
		ValidationService.raise_validation_errors(ValidationService.validate_country_supported(country))

		# Check if the user already has a provider
		ValidationService.raise_validation_errors(ValidationService.validate_provider_nonexistence(session.user.provider))

		# Create the stripe account
		account = Stripe::Account.create({
			type: 'custom',
			requested_capabilities: [
				'card_payments',
				'transfers'
			],
			business_type: 'individual',
			email: session.user.email,
			country: country,
			settings: {
				payouts: {
					schedule: {
						interval: "monthly",
						monthly_anchor: 13
					}
				}
			}
		})

		# Create the provider
		provider = Provider.new(
			user: session.user,
			stripe_account_id: account.id
		)
		ValidationService.raise_unexpected_error(!provider.save)

		# Return the data
		result = {
			id: provider.id,
			user_id: provider.user_id,
			stripe_account_id: provider.stripe_account_id
		}
		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def get_provider
		access_token = get_auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Get the provider
		provider = session.user.provider
		ValidationService.raise_validation_errors(ValidationService.validate_provider_existence(provider))

		# Return the data
		result = {
			id: provider.id,
			user_id: provider.user_id,
			stripe_account_id: provider.stripe_account_id
		}
		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end