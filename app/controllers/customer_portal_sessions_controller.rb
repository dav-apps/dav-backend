class CustomerPortalSessionsController < ApplicationController
	def create_customer_portal_session
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Make sure the user has a stripe customer
		ValidationService.raise_validation_errors(ValidationService.validate_user_is_stripe_customer(user))

		begin
			# Create the session
			portal_session = Stripe::BillingPortal::Session.create({
				customer: user.stripe_customer_id
			})
		rescue => e
			RorVsWild.record_error(e)
			ValidationService.raise_unexpected_error
		end

		result = {
			session_url: portal_session.url
		}

		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end
end