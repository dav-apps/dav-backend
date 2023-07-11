class PurchasesController < ApplicationController
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

	# v2
	def list_purchases_of_table_object
		auth = get_auth
		uuid = params[:uuid]
		user_id = params[:user_id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))

		# Get the purchases of the table object
		purchases = Array.new

		if user_id.nil?
			purchases = table_object.purchases.find_by(completed: true)
		else
			purchases = table_object.purchases.find_by(user_id: user_id, completed: true)
		end

		# Return the data
		purchases_result = Array.new

		purchases.each do |purchase|
			purchases_result.push({
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
			})
		end

		result = {
			purchases: purchases_result
		}

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end
