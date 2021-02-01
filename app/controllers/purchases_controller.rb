class PurchasesController < ApplicationController
	def create_purchase
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		provider_name = body["provider_name"]
		provider_image = body["provider_image"]
		product_name = body["product_name"]
		product_image = body["product_image"]
		currency = body["currency"]

		# Validate missing fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_provider_name_presence(provider_name),
			ValidationService.validate_provider_image_presence(provider_image),
			ValidationService.validate_product_name_presence(product_name),
			ValidationService.validate_product_image_presence(product_image),
			ValidationService.validate_currency_presence(currency)
		])

		# Validate the types of the fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_provider_name_type(provider_name),
			ValidationService.validate_provider_image_type(provider_image),
			ValidationService.validate_product_name_type(product_name),
			ValidationService.validate_product_image_type(product_image),
			ValidationService.validate_currency_type(currency)
		])

		# Validate the length of the fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_provider_name_length(provider_name),
			ValidationService.validate_provider_image_length(provider_image),
			ValidationService.validate_product_name_length(product_name),
			ValidationService.validate_product_image_length(product_image)
		])

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)
		ValidationService.raise_validation_error(ValidationService.validate_table_object_existence(table_object))

		# Check if the table object belongs to the app of the session
		ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))

		# Check if the user already purchased the table object
		ValidationService.raise_validation_error(ValidationService.validate_purchase_nonexistence(Purchase.find_by(user: user, table_object: table_object)))

		# Get the price of the table object in the specified currency
		table_object_price = TableObjectPrice.find_by(table_object: table_object, currency: currency.downcase)
		ValidationService.raise_validation_error(ValidationService.validate_table_object_price_existence(table_object_price))
		price = table_object_price.price

		# If the object belongs to the user, set the price to 0
		price = 0 if table_object.user == user

		if price > 0
			# Check if the user of the table object has a provider
			ValidationService.raise_validation_error(ValidationService.validate_user_is_provider(table_object.user))
		end

		# Create the purchase
		purchase = Purchase.new(
			user: user,
			table_object: table_object,
			provider_name: provider_name,
			provider_image: provider_image,
			product_name: product_name,
			product_image: product_image,
			price: price,
			currency: table_object_price.currency
		)

		if price == 0
			purchase.completed = true
		else
			# Create a stripe customer for the user, if the user has none
			if user.stripe_customer_id.nil?
				customer = Stripe::Customer.create(email: user.email)
				user.stripe_customer_id = customer.id
				ValidationService.raise_unexpected_error(!user.save)
			end

			# Create a payment intent
			payment_intent = Stripe::PaymentIntent.create({
				customer: user.stripe_customer_id,
				amount: price,
				currency: currency.downcase,
				confirmation_method: 'manual',
				application_fee_amount: (price * 0.2).round,
				transfer_data: {
					destination: table_object.user.provider.stripe_account_id
				}
			})

			purchase.payment_intent_id = payment_intent.id
		end
		
		ValidationService.raise_unexpected_error(!purchase.save)

		# Return the data
		result = {
			id: purchase.id,
			user_id: purchase.user_id,
			table_object_id: purchase.table_object_id,
			payment_intent_id: purchase.payment_intent_id,
			provider_name: purchase.provider_name,
			provider_image: purchase.provider_image,
			product_name: purchase.product_name,
			product_image: purchase.product_image,
			price: purchase.price,
			currency: purchase.currency,
			completed: purchase.completed
		}
		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end