class PurchasesController < ApplicationController
	def create_purchase
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

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
		table_object_uuids = body["table_objects"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_provider_name_presence(provider_name),
			ValidationService.validate_provider_image_presence(provider_image),
			ValidationService.validate_product_name_presence(product_name),
			ValidationService.validate_product_image_presence(product_image),
			ValidationService.validate_currency_presence(currency),
			ValidationService.validate_table_objects_presence(table_object_uuids)
		])

		# Validate the types of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_provider_name_type(provider_name),
			ValidationService.validate_provider_image_type(provider_image),
			ValidationService.validate_product_name_type(product_name),
			ValidationService.validate_product_image_type(product_image),
			ValidationService.validate_currency_type(currency),
			ValidationService.validate_table_objects_type(table_object_uuids)
		])

		# Validate the length of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_provider_name_length(provider_name),
			ValidationService.validate_provider_image_length(provider_image),
			ValidationService.validate_product_name_length(product_name),
			ValidationService.validate_product_image_length(product_image)
		])

		# Validate length of table objects
		ValidationService.raise_validation_errors(ValidationService.validate_table_objects_count(table_object_uuids))

		table_objects = Array.new
		table_object_uuids.each do |uuid|
			# Get the table object
			table_object = TableObject.find_by(uuid: uuid)
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))

			# Check if the table object belongs to the app of the session
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_app(table_object, session.app))

			table_objects.push(table_object)
		end

		# Check if the table objects belong to the same user
		obj_user = table_objects.first.user
		ValidationService.raise_validation_errors(ValidationService.validate_table_objects_belong_to_same_user(table_objects))

		# Check if the user already purchased one of the table objects
		ValidationService.raise_validation_errors(ValidationService.validate_table_objects_already_purchased(session.user, table_objects))

		# Get the price of the first table object in the specified currency
		table_object_price = TableObjectPrice.find_by(table_object: table_objects.first, currency: currency.downcase)
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_price_existence(table_object_price))
		price = table_object_price.price

		# If the object belongs to the user, set the price to 0
		price = 0 if table_objects.first.user == user

		if price > 0
			# Check if the user of the table object has a provider
			ValidationService.raise_validation_errors(ValidationService.validate_user_is_provider(obj_user))
		end

		# Create the purchase
		purchase = Purchase.new(
			user: user,
			uuid: SecureRandom.uuid,
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
			begin
				payment_intent = Stripe::PaymentIntent.create({
					customer: user.stripe_customer_id,
					amount: price,
					currency: currency.downcase,
					confirmation_method: 'manual',
					application_fee_amount: (price * 0.2).round,
					transfer_data: {
						destination: obj_user.provider.stripe_account_id
					}
				})
			rescue Stripe::CardError => e
				ValidationService.raise_unexpected_error
			end
			
			purchase.payment_intent_id = payment_intent.id
		end
		
		# Create the TableObjectPurchases
		table_objects.each do |obj|
			table_object_purchase = TableObjectPurchase.new(
				table_object: obj,
				purchase: purchase
			)

			ValidationService.raise_unexpected_error(!table_object_purchase.save)
		end

		# Return the data
		result = {
			id: purchase.id,
			user_id: purchase.user_id,
			uuid: purchase.uuid,
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
		render_errors(e)
	end

	def get_purchase
		auth = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the purchase
		purchase = Purchase.find_by(uuid: uuid)
		ValidationService.raise_validation_errors(ValidationService.validate_purchase_existence(purchase))

		# Return the data
		result = {
			id: purchase.id,
			user_id: purchase.user_id,
			uuid: purchase.uuid,
			payment_intent_id: purchase.payment_intent_id,
			provider_name: purchase.provider_name,
			provider_image: purchase.provider_image,
			product_name: purchase.product_name,
			product_image: purchase.product_image,
			price: purchase.price,
			currency: purchase.currency,
			completed: purchase.completed
		}
		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def delete_purchase
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user

		# Get the purchase
		purchase = Purchase.find_by(uuid: uuid)
		ValidationService.raise_validation_errors(ValidationService.validate_purchase_existence(purchase))

		# Check if the purchase belongs to the user
		ValidationService.raise_validation_errors(ValidationService.validate_purchase_belongs_to_user(purchase, user))

		# Check if the purchase belongs to the app of the session
		ValidationService.raise_validation_errors(ValidationService.validate_purchase_belongs_to_app(purchase, session.app))

		# Check if the purchase can be deleted
		ValidationService.raise_validation_errors(ValidationService.validate_purchase_can_be_deleted(purchase))

		# Cancel the payment intent
		if purchase.price > 0
			Stripe::PaymentIntent.cancel(purchase.payment_intent_id)
		end

		# Delete the purchase
		purchase.destroy!

		head 204, content_type: "application/json"
	rescue => e
		render_errors(e)
	end
end