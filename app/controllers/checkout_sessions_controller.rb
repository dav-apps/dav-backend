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
		mode = body["mode"]
		plan = body["plan"]
		currency = body["currency"]
		product_name = body["product_name"]
		product_image = body["product_image"]
		table_object_uuids = body["table_objects"]
		success_url = body["success_url"]
		cancel_url = body["cancel_url"]

		if mode.nil?
			mode = "subscription"
		else
			# Validate the mode
			ValidationService.raise_validation_errors(ValidationService.validate_mode_type(mode))
			ValidationService.raise_validation_errors(ValidationService.validate_mode_validity(mode))
		end

		# Validate missing fields
		validations = Array.new
		validations.push(ValidationService.validate_plan_presence(plan)) if mode == "subscription"
		validations.push(ValidationService.validate_currency_presence(currency)) if mode == "payment"
		validations.push(ValidationService.validate_product_name_presence(product_name)) if mode == "payment"
		validations.push(ValidationService.validate_product_image_presence(product_image)) if mode == "payment"
		validations.push(ValidationService.validate_table_objects_presence(table_object_uuids)) if mode == "payment"
		validations.push(ValidationService.validate_success_url_presence(success_url))
		validations.push(ValidationService.validate_cancel_url_presence(cancel_url))
		ValidationService.raise_validation_errors(validations)

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_plan_type(plan)) if mode == "subscription"
		validations.push(ValidationService.validate_currency_type(currency)) if mode == "payment"
		validations.push(ValidationService.validate_product_name_type(product_name)) if mode == "payment"
		validations.push(ValidationService.validate_product_image_type(product_image)) if mode == "payment"
		validations.push(ValidationService.validate_table_objects_type(table_object_uuids)) if mode == "payment"
		validations.push(ValidationService.validate_success_url_type(success_url))
		validations.push(ValidationService.validate_cancel_url_type(cancel_url))
		ValidationService.raise_validation_errors(validations)

		# Validate the length of the fields
		validations = Array.new
		validations.push(ValidationService.validate_product_image_length(product_image)) if mode == "payment"
		ValidationService.raise_validation_errors(validations)

		# Validate the validity of the fields
		validations = Array.new
		validations.push(ValidationService.validate_plan_validity(plan)) if mode == "subscription"
		validations.push(ValidationService.validate_product_image_validity(product_image)) if mode == "payment"
		validations.push(ValidationService.validate_success_url_validity(success_url))
		validations.push(ValidationService.validate_cancel_url_validity(cancel_url))
		ValidationService.raise_validation_errors(validations)

		if mode == "subscription"
			# Check if the user is below the given plan
			ValidationService.raise_validation_errors([
				ValidationService.validate_user_is_below_plan(session.user, plan)
			])
		end

		if mode == "payment"
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
				product_name: product_name,
				product_image: product_image,
				price: price,
				currency: table_object_price.currency
			)

			if price == 0
				purchase.completed = true
			end
		end

		# Create a stripe customer, if the user has none
		if user.stripe_customer_id.nil?
			customer = Stripe::Customer.create(
				email: user.email
			)

			user.stripe_customer_id = customer.id
			ValidationService.raise_unexpected_error(!user.save)
		end

		begin
			if mode == "subscription"
				# Create the checkout session
				plan_id = ENV["STRIPE_DAV_PLUS_EUR_PLAN_ID"]
				plan_id = ENV["STRIPE_DAV_PRO_EUR_PLAN_ID"] if plan == 2
	
				session = Stripe::Checkout::Session.create({
					customer: user.stripe_customer_id,
					mode: "subscription",
					line_items: [{
						price: plan_id,
						quantity: 1,
					}],
					success_url: success_url,
					cancel_url: cancel_url
				})
			elsif mode == "payment" && price > 0
				session = Stripe::Checkout::Session.create({
					customer: user.stripe_customer_id,
					mode: "payment",
					line_items: [{
						quantity: 1,
						price_data: {
							currency: table_object_price.currency,
							unit_amount: price,
							product_data: {
								name: product_name,
								images: [product_image]
							}
						}
					}],
					payment_intent_data: {
						application_fee_amount: (price * 0.2).round,
						transfer_data: {
							destination: obj_user.provider.stripe_account_id
						}
					},
					success_url: success_url,
					cancel_url: cancel_url
				})

				purchase.payment_intent_id = session.payment_intent
			elsif mode == "setup"
				session = Stripe::Checkout::Session.create({
					customer: user.stripe_customer_id,
					payment_method_types: ["card"],
					mode: "setup",
					success_url: success_url,
					cancel_url: cancel_url
				})
			end
		rescue => e
			RorVsWild.record_error(e)
			ValidationService.raise_unexpected_error
		end

		if mode == "payment"
			# Create the TableObjectPurchases
			table_objects.each do |obj|
				table_object_purchase = TableObjectPurchase.new(
					table_object: obj,
					purchase: purchase
				)

				ValidationService.raise_unexpected_error(!table_object_purchase.save)
			end
		end

		# Return the data
		result = {
			session_url: session.url
		}

		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end
end