require "test_helper"

describe PurchasesController do
	setup do
		setup
	end

	# create_purchase
	it "should not create purchase without access token" do
		res = post_request("/v1/table_object/asd/purchase")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create purchase without Content-Type json" do
		res = post_request(
			"/v1/table_object/asd/purchase",
			{Authorization: "iojsdjiosdfjiosdf"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create purchase with access token for session that does not exist" do
		res = post_request(
			"/v1/table_object/asd/purchase",
			{Authorization: "ioafhiosdfiosfd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create purchase without required properties" do
		res = post_request(
			"/v1/table_object/asd/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_MISSING, res["errors"][3]["code"])
		assert_equal(ErrorCodes::CURRENCY_MISSING, res["errors"][4]["code"])
	end

	it "should not create purchase with properties with wrong types" do
		res = post_request(
			"/v1/table_object/asd/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: true,
				provider_image: false,
				product_name: 12,
				product_image: 52.3,
				currency: 40
			}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::CURRENCY_WRONG_TYPE, res["errors"][4]["code"])
	end

	it "should not create purchase with too short properties" do
		res = post_request(
			"/v1/table_object/asd/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "a",
				provider_image: "a",
				product_name: "a",
				product_image: "a",
				currency: "eur"
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_TOO_SHORT, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_TOO_SHORT, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_TOO_SHORT, res["errors"][3]["code"])
	end

	it "should not create purchase with too long properties" do
		res = post_request(
			"/v1/table_object/asd/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "a" * 300,
				provider_image: "a" * 300,
				product_name: "a" * 300,
				product_image: "a" * 300,
				currency: "eur"
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_TOO_LONG, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_TOO_LONG, res["errors"][3]["code"])
	end

	it "should not create purchase for table object that does not exist" do
		res = post_request(
			"/v1/table_object/asdasdasdasd/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create purchase for table object that belongs to another app" do
		res = post_request(
			"/v1/table_object/#{table_objects(:sherlockTestData).uuid}/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create purchase for table object that is already purchased" do
		res = post_request(
			"/v1/table_object/#{table_objects(:snicketFirstBook).uuid}/purchase",
			{Authorization: sessions(:mattPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur"
			}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_ALREADY_EXISTS, res["errors"][0]["code"])
	end

	it "should not create purchase for table object that has no price for the given currency" do
		res = post_request(
			"/v1/table_object/#{table_objects(:snicketFirstBook).uuid}/purchase",
			{Authorization: sessions(:catoPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "usd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_PRICE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create purchase for table object whose user is not a provider" do
		table_object = table_objects(:mattFirstCard)

		TableObjectPrice.create(
			table_object: table_object,
			price: 1000,
			currency: "eur"
		)

		res = post_request(
			"/v1/table_object/#{table_object.uuid}/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur"
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_OF_TABLE_OBJECT_MUST_BE_PROVIDER, res["errors"][0]["code"])
	end

	it "should create purchase" do
		cato = users(:cato)
		snicket_provider = providers(:snicket)
		table_object = table_objects(:snicketFirstBook)
		table_object_price = table_object_prices(:snicketFirstBookEur)
		provider_name = "Lemony Snicket"
		provider_image = "https://api.pocketlib.app/author/sadasdasd/profile_image"
		product_name = "A Series of Unfortunate Events - Book the First"
		product_image = "https://api.pocketlib.app/store/book/asdasdasd/cover"
		price = table_object_price.price
		currency = table_object_price.currency
		
		res = post_request(
			"/v1/table_object/#{table_object.uuid}/purchase",
			{Authorization: sessions(:catoPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: provider_name,
				provider_image: provider_image,
				product_name: product_name,
				product_image: product_image,
				currency: currency
			}
		)

		assert_response 201
		
		assert_not_nil(res["id"])
		assert_equal(cato.id, res["user_id"])
		assert_equal(table_object.id, res["table_object_id"])
		assert_not_nil(res["payment_intent_id"])
		assert_equal(provider_name, res["provider_name"])
		assert_equal(provider_image, res["provider_image"])
		assert_equal(product_name, res["product_name"])
		assert_equal(product_image, res["product_image"])
		assert_equal(price, res["price"])
		assert_equal(currency, res["currency"])
		assert(!res["completed"])

		purchase = Purchase.find_by(id: res["id"])
		assert_not_nil(purchase)
		assert_equal(purchase.user_id, res["user_id"])
		assert_equal(purchase.table_object_id, res["table_object_id"])
		assert_equal(purchase.payment_intent_id, res["payment_intent_id"])
		assert_equal(purchase.provider_name, res["provider_name"])
		assert_equal(purchase.provider_image, res["provider_image"])
		assert_equal(purchase.product_name, res["product_name"])
		assert_equal(purchase.product_image, res["product_image"])
		assert_equal(purchase.price, res["price"])
		assert_equal(purchase.currency, res["currency"])

		# Get the payment intent
		payment_intent = Stripe::PaymentIntent.retrieve(purchase.payment_intent_id)
		assert_not_nil(payment_intent)
		assert_equal(price, payment_intent.amount)
		assert_equal(currency, payment_intent.currency)
		assert_equal(snicket_provider.stripe_account_id, payment_intent.transfer_data.destination)

		# Get the new stripe customer of the user
		cato = User.find_by(id: cato.id)
		customer = Stripe::Customer.retrieve(cato.stripe_customer_id)
		assert_not_nil(customer)
		assert_equal(cato.email, customer.email)
		Stripe::Customer.delete(cato.stripe_customer_id)
	end

	it "should create purchase for own table object" do
		snicket = users(:snicket)
		table_object = table_objects(:snicketFirstBook)
		table_object_price = table_object_prices(:snicketFirstBookEur)
		provider_name = "Lemony Snicket"
		provider_image = "https://api.pocketlib.app/author/sadasdasd/profile_image"
		product_name = "A Series of Unfortunate Events - Book the First"
		product_image = "https://api.pocketlib.app/store/book/asdasdasd/cover"
		currency = table_object_price.currency

		res = post_request(
			"/v1/table_object/#{table_object.uuid}/purchase",
			{Authorization: sessions(:snicketPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: provider_name,
				provider_image: provider_image,
				product_name: product_name,
				product_image: product_image,
				currency: currency
			}
		)

		assert_response 201

		assert_not_nil(res["id"])
		assert_equal(snicket.id, res["user_id"])
		assert_equal(table_object.id, res["table_object_id"])
		assert_nil(res["payment_intent_id"])
		assert_equal(provider_name, res["provider_name"])
		assert_equal(provider_image, res["provider_image"])
		assert_equal(product_name, res["product_name"])
		assert_equal(product_image, res["product_image"])
		assert_equal(0, res["price"])
		assert_equal(currency, res["currency"])
		assert(res["completed"])

		purchase = Purchase.find_by(id: res["id"])
		assert_not_nil(purchase)
		assert_equal(purchase.user_id, res["user_id"])
		assert_equal(purchase.table_object_id, res["table_object_id"])
		assert_nil(res["payment_intent_id"])
		assert_equal(purchase.provider_name, res["provider_name"])
		assert_equal(purchase.provider_image, res["provider_image"])
		assert_equal(purchase.product_name, res["product_name"])
		assert_equal(purchase.product_image, res["product_image"])
		assert_equal(0, res["price"])
		assert_equal(purchase.currency, res["currency"])
	end
end