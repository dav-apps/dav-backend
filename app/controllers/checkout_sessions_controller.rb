class CheckoutSessionsController < ApplicationController
	def create_checkout_session
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))
		
		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		plan = body["plan"]
		success_url = body["success_url"]
		cancel_url = body["cancel_url"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_plan_presence(plan),
			ValidationService.validate_success_url_presence(success_url),
			ValidationService.validate_cancel_url_presence(cancel_url)
		])

		# Validate the types of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_plan_type(plan),
			ValidationService.validate_success_url_type(success_url),
			ValidationService.validate_cancel_url_type(cancel_url)
		])

		# Validate the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_success_url_length(success_url),
			ValidationService.validate_cancel_url_length(cancel_url)
		])

		ValidationService.raise_validation_errors([
			ValidationService.validate_plan_validity(plan),
			ValidationService.validate_success_url_validity(success_url),
			ValidationService.validate_cancel_url_validity(cancel_url)
		])

		# Check if the user is below the given plan
		ValidationService.raise_validation_errors([
			ValidationService.validate_user_is_below_plan(session.user, plan)
		])

		# Create a stripe customer, if the user has none
		if user.stripe_customer_id.nil?
			customer = Stripe::Customer.create(
				email: user.email
			)

			user.stripe_customer_id = customer.id
			ValidationService.raise_unexpected_error(!user.save)
		end

		# Create the checkout session
		plan_id = ENV["STRIPE_DAV_PLUS_EUR_PLAN_ID"]
		plan_id = ENV["STRIPE_DAV_PRO_EUR_PLAN_ID"] if plan == 2

		session = Stripe::Checkout::Session.create({
			customer: user.stripe_customer_id,
			line_items: [{
				price: plan_id,
				quantity: 1,
			}],
			mode: 'subscription',
			success_url: success_url,
			cancel_url: cancel_url
		})

		# Return the data
		result = {
			session_url: session.url
		}

		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end
end