require "test_helper"

describe CheckoutSessionsController do
	setup do
		setup
	end

	# create_checkout_session
	it "should not create checkout session without access token" do
		res = post_request("/v1/checkout_session")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create checkout session without Content-Type json" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: "sasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create checkout session with access token for session that does not exist" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create checkout session without required properties" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::PLAN_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::SUCCESS_URL_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::CANCEL_URL_MISSING, res["errors"][2]["code"])
	end

	it "should not create checkout session without required properties in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment"
			}
		)

		assert_response 400
		assert_equal(6, res["errors"].length)
		assert_equal(ErrorCodes::CURRENCY_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCodes::TABLE_OBJECTS_MISSING, res["errors"][3]["code"])
		assert_equal(ErrorCodes::SUCCESS_URL_MISSING, res["errors"][4]["code"])
		assert_equal(ErrorCodes::CANCEL_URL_MISSING, res["errors"][5]["code"])
	end

	it "should not create checkout session with properties with wrong types" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				plan: "1",
				success_url: 12,
				cancel_url: true
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::PLAN_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::SUCCESS_URL_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::CANCEL_URL_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not create checkout session with properties with wrong types in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: 1,
				product_name: true,
				product_image: false,
				table_objects: [123],
				success_url: 12,
				cancel_url: true
			}
		)

		assert_response 400
		assert_equal(6, res["errors"].length)
		assert_equal(ErrorCodes::CURRENCY_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::TABLE_OBJECTS_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::SUCCESS_URL_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCodes::CANCEL_URL_WRONG_TYPE, res["errors"][5]["code"])
	end

	it "should not create checkout session with properties with wrong types with different mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: 1234,
				success_url: 12,
				cancel_url: true
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::MODE_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not create checkout session with too long properties in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "a" * 300,
				table_objects: ["asdsd"],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PRODUCT_IMAGE_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not create checkout session with invalid properties" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				plan: 0,
				success_url: "ftp://bla.com",
				cancel_url: "ljskdfklsdf"
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::PLAN_INVALID, res["errors"][0]["code"])
		assert_equal(ErrorCodes::SUCCESS_URL_INVALID, res["errors"][1]["code"])
		assert_equal(ErrorCodes::CANCEL_URL_INVALID, res["errors"][2]["code"])
	end

	it "should not create checkout session with invalid properties in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "aasdasasd",
				table_objects: ["asdsd"],
				success_url: "sdasdfdfsa",
				cancel_url: "jkhsdfsdf"
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::PRODUCT_IMAGE_INVALID, res["errors"][0]["code"])
		assert_equal(ErrorCodes::SUCCESS_URL_INVALID, res["errors"][1]["code"])
		assert_equal(ErrorCodes::CANCEL_URL_INVALID, res["errors"][2]["code"])
	end

	it "should not create checkout session with invalid properties with different mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "asdasd",
				success_url: "ftp://bla.com",
				cancel_url: "ljskdfklsdf"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::MODE_INVALID, res["errors"][0]["code"])
	end

	it "should not create checkout session for user that is already on the plan" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:violetPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				plan: 1,
				success_url: "https://universalsoundboard.dav-apps.tech/redirect?success=true&plan=1",
				cancel_url: "https://universalsoundboard.dav-apps.tech/redirect?success=false"
			}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_IS_ALREADY_ON_PLAN, res["errors"][0]["code"])
	end

	it "should not create checkout session without table objects in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "https://dav-apps.tech",
				table_objects: [],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_REQUIRES_AT_LEAST_ONE_TABLE_OBJECT, res["errors"][0]["code"])
	end

	it "should not create checkout session with table objects that do not exist in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "https://dav-apps.tech",
				table_objects: ["asdasd", "asdasd"],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create checkout session with table objects that belong to another app in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "https://dav-apps.tech",
				table_objects: [table_objects(:sherlockTestData).uuid],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create checkout session with table objects that belong to different users in payment mode" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "https://dav-apps.tech",
				table_objects: [
					table_objects(:snicketSecondBook).uuid,
					table_objects(:hindenburgFirstBook).uuid
				],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECTS_NEED_TO_BELONG_TO_THE_SAME_USER, res["errors"][0]["code"])
	end

	it "should not create checkout session with table object that is already purchased" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "https://dav-apps.tech",
				table_objects: [table_objects(:snicketFirstBook).uuid],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_ALREADY_PURCHASED_THIS_TABLE_OBJECT, res["errors"][0]["code"])
	end

	it "should not create checkout session with table object that has no price for the given currency" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:catoPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "usd",
				product_name: "Test",
				product_image: "https://dav-apps.tech",
				table_objects: [table_objects(:snicketFirstBook).uuid],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_PRICE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create checkout session with table object whose user is not a provider" do
		table_object = table_objects(:mattFirstCard)

		TableObjectPrice.create(
			table_object: table_object,
			price: 1000,
			currency: "eur"
		)

		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: "eur",
				product_name: "Test",
				product_image: "https://dav-apps.tech",
				table_objects: [table_object.uuid],
				success_url: "https://dav-apps.tech",
				cancel_url: "https://dav-apps.tech"
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_OF_TABLE_OBJECT_MUST_HAVE_PROVIDER, res["errors"][0]["code"])
	end

	it "should create checkout session" do
		success_url = "https://universalsoundboard.dav-apps.tech/redirect?success=true&plan=1"
		cancel_url = "https://universalsoundboard.dav-apps.tech/redirect?success=false"

		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				plan: 1,
				success_url: success_url,
				cancel_url: cancel_url
			}
		)

		assert_response 201

		# Get the checkout session
		sessions = Stripe::Checkout::Session.list({ limit: 1 })
		assert_equal(sessions.data.length, 1)

		session = sessions.data[0]
		assert_equal(session.url, res["session_url"])
		assert_equal(session.mode, "subscription")
		assert_equal(session.success_url, success_url)
		assert_equal(session.cancel_url, cancel_url)
	end

	it "should create checkout session and stripe customer for user" do
		success_url = "https://universalsoundboard.dav-apps.tech/redirect?success=true&plan=1"
		cancel_url = "https://universalsoundboard.dav-apps.tech/redirect?success=false"

		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:catoWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				plan: 1,
				success_url: success_url,
				cancel_url: cancel_url
			}
		)

		assert_response 201

		# Get the stripe customer
		user = User.find_by(id: users(:cato).id)
		assert_not_nil(user)
		assert_not_nil(user.stripe_customer_id)

		customer = Stripe::Customer.retrieve(user.stripe_customer_id)
		assert_not_nil(customer)
		assert_equal(customer.email, user.email)

		# Get the checkout session
		sessions = Stripe::Checkout::Session.list({ limit: 1 })
		assert_equal(sessions.data.length, 1)

		session = sessions.data[0]
		assert_equal(session.url, res["session_url"])
		assert_equal(session.mode, "subscription")
		assert_equal(session.success_url, success_url)
		assert_equal(session.cancel_url, cancel_url)

		Stripe::Customer.delete(customer.id)
	end

	it "should create checkout session in setup mode" do
		success_url = "https://dav-apps.tech/user?success=true#plans"
		cancel_url = "https://dav-apps.tech/user#plans"

		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				mode: "setup",
				success_url: success_url,
				cancel_url: cancel_url
			}
		)

		assert_response 201

		# Get the checkout session
		sessions = Stripe::Checkout::Session.list({ limit: 1 })
		assert_equal(sessions.data.length, 1)

		session = sessions.data[0]
		assert_equal(session.url, res["session_url"])
		assert_equal(session.mode, "setup")
		assert_equal(session.success_url, success_url)
		assert_equal(session.cancel_url, cancel_url)
	end

	it "should create checkout session in payment mode" do
		cato = users(:cato)
		success_url = "https://dav-apps.tech/user?success=true#plans"
		cancel_url = "https://dav-apps.tech/user#plans"
		product_name = "A Series of Unfortunate Events - Book the First"
		product_image = "https://api.pocketlib.app/store/book/asdasdasd/cover"
		first_table_object = table_objects(:snicketFirstBook)
		second_table_object = table_objects(:snicketSecondBook)
		table_object_price = table_object_prices(:snicketFirstBookEur)
		price = table_object_price.price
		currency = table_object_price.currency

		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:catoPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				mode: "payment",
				currency: currency,
				product_name: product_name,
				product_image: product_image,
				table_objects: [
					first_table_object.uuid,
					second_table_object.uuid
				],
				success_url: success_url,
				cancel_url: cancel_url
			}
		)

		assert_response 201

		# Get the checkout session
		sessions = Stripe::Checkout::Session.list({ limit: 1 })
		assert_equal(sessions.data.length, 1)

		session = sessions.data[0]
		assert_equal(session.url, res["session_url"])
		assert_equal(session.mode, "payment")
		assert_equal(session.success_url, success_url)
		assert_equal(session.cancel_url, cancel_url)

		purchase = cato.purchases.last
		assert_not_nil(purchase)
		assert_equal(purchase.user_id, cato.id)
		assert_not_nil(purchase.uuid)
		assert_equal(purchase.payment_intent_id, session.payment_intent)
		assert_nil(purchase.provider_name)
		assert_nil(purchase.provider_image)
		assert_equal(purchase.product_name, product_name)
		assert_equal(purchase.product_image, product_image)
		assert_equal(purchase.price, price)
		assert_equal(purchase.currency, currency)

		first_table_object_purchase = TableObjectPurchase.find_by(purchase: purchase, table_object: first_table_object)
		assert_not_nil(first_table_object_purchase)
		assert_equal(first_table_object_purchase.purchase_id, purchase.id)
		assert_equal(first_table_object_purchase.table_object_id, first_table_object.id)

		second_table_object_purchase = TableObjectPurchase.find_by(purchase: purchase, table_object: second_table_object)
		assert_not_nil(second_table_object_purchase)
		assert_equal(second_table_object_purchase.purchase_id, purchase.id)
		assert_equal(second_table_object_purchase.table_object_id, second_table_object.id)


	end
end