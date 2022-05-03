require "test_helper"

describe PurchasesController do
	setup do
		setup
	end

	# create_purchase
	it "should not create purchase without access token" do
		res = post_request("/v1/purchase")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create purchase without Content-Type json" do
		res = post_request(
			"/v1/purchase",
			{Authorization: "iojsdjiosdfjiosdf"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create purchase with access token for session that does not exist" do
		res = post_request(
			"/v1/purchase",
			{Authorization: "ioafhiosdfiosfd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create purchase without required properties" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(6, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_MISSING, res["errors"][3]["code"])
		assert_equal(ErrorCodes::CURRENCY_MISSING, res["errors"][4]["code"])
		assert_equal(ErrorCodes::TABLE_OBJECTS_MISSING, res["errors"][5]["code"])
	end

	it "should not create purchase with properties with wrong types" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: true,
				provider_image: false,
				product_name: 12,
				product_image: 52.3,
				currency: 40,
				table_objects: "test"
			}
		)

		assert_response 400
		assert_equal(6, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::CURRENCY_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCodes::TABLE_OBJECTS_WRONG_TYPE, res["errors"][5]["code"])
	end

	it "should not create purchase with too short properties" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "a",
				provider_image: "a",
				product_name: "a",
				product_image: "a",
				currency: "eur",
				table_objects: ["asdasd"]
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_TOO_SHORT, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_TOO_SHORT, res["errors"][2]["code"])
	end

	it "should not create purchase with too long properties" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "a" * 300,
				provider_image: "a" * 300,
				product_name: "a" * 300,
				product_image: "a" * 300,
				currency: "eur",
				table_objects: ["asdasd"]
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PROVIDER_IMAGE_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PRODUCT_NAME_TOO_LONG, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PRODUCT_IMAGE_TOO_LONG, res["errors"][3]["code"])
	end

	it "should not create purchase without table objects" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur",
				table_objects: []
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_REQUIRES_AT_LEAST_ONE_TABLE_OBJECT, res["errors"][0]["code"])
	end

	it "should not create purchase for table objects that do not exist" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur",
				table_objects: ["sdofshodfosidf"]
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create purchase for table objects that belong to another app" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur",
				table_objects: [table_objects(:sherlockTestData).uuid]
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create purchase for table objects that belong to different users" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:mattPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur",
				table_objects: [
					table_objects(:snicketSecondBook).uuid,
					table_objects(:hindenburgFirstBook).uuid
				]
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECTS_NEED_TO_BELONG_TO_THE_SAME_USER, res["errors"][0]["code"])
	end

	it "should not create purchase for table object that is already purchased" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:mattPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur",
				table_objects: [table_objects(:snicketFirstBook).uuid]
			}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_ALREADY_PURCHASED_THIS_TABLE_OBJECT, res["errors"][0]["code"])
	end

	it "should not create purchase for table object that has no price for the given currency" do
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:catoPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "usd",
				table_objects: [table_objects(:snicketFirstBook).uuid]
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
			"/v1/purchase",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: "Lemony Snicket",
				provider_image: "https://api.pocketlib.app/author/asd/profile_image",
				product_name: "A Series of Unfortunate Events - Book the First",
				product_image: "https://api.pocketlib.app/store/book/asd/cover",
				currency: "eur",
				table_objects: [table_object.uuid]
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_OF_TABLE_OBJECT_MUST_HAVE_PROVIDER, res["errors"][0]["code"])
	end

	it "should create purchase" do
		cato = users(:cato)
		snicket_provider = providers(:snicket)
		first_table_object = table_objects(:snicketFirstBook)
		second_table_object = table_objects(:snicketSecondBook)
		table_object_price = table_object_prices(:snicketFirstBookEur)
		provider_name = "Lemony Snicket"
		provider_image = "https://api.pocketlib.app/author/sadasdasd/profile_image"
		product_name = "A Series of Unfortunate Events - Book the First"
		product_image = "https://api.pocketlib.app/store/book/asdasdasd/cover"
		price = table_object_price.price
		currency = table_object_price.currency
		
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:catoPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: provider_name,
				provider_image: provider_image,
				product_name: product_name,
				product_image: product_image,
				currency: currency,
				table_objects: [
					first_table_object.uuid,
					second_table_object.uuid
				]
			}
		)

		assert_response 201
		
		assert_not_nil(res["id"])
		assert_equal(cato.id, res["user_id"])
		assert_not_nil(res["uuid"])
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
		assert_equal(purchase.uuid, res["uuid"])
		assert_equal(purchase.payment_intent_id, res["payment_intent_id"])
		assert_equal(purchase.provider_name, res["provider_name"])
		assert_equal(purchase.provider_image, res["provider_image"])
		assert_equal(purchase.product_name, res["product_name"])
		assert_equal(purchase.product_image, res["product_image"])
		assert_equal(purchase.price, res["price"])
		assert_equal(purchase.currency, res["currency"])

		first_table_object_purchase = TableObjectPurchase.find_by(purchase: purchase, table_object: first_table_object)
		assert_not_nil(first_table_object_purchase)
		assert_equal(first_table_object_purchase.purchase_id, purchase.id)
		assert_equal(first_table_object_purchase.table_object_id, first_table_object.id)

		second_table_object_purchase = TableObjectPurchase.find_by(purchase: purchase, table_object: second_table_object)
		assert_not_nil(second_table_object_purchase)
		assert_equal(second_table_object_purchase.purchase_id, purchase.id)
		assert_equal(second_table_object_purchase.table_object_id, second_table_object.id)

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
			"/v1/purchase",
			{Authorization: sessions(:snicketPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: provider_name,
				provider_image: provider_image,
				product_name: product_name,
				product_image: product_image,
				currency: currency,
				table_objects: [table_object.uuid]
			}
		)

		assert_response 201

		assert_not_nil(res["id"])
		assert_equal(snicket.id, res["user_id"])
		assert_not_nil(res["uuid"])
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
		assert_equal(purchase.uuid, res["uuid"])
		assert_nil(res["payment_intent_id"])
		assert_equal(purchase.provider_name, res["provider_name"])
		assert_equal(purchase.provider_image, res["provider_image"])
		assert_equal(purchase.product_name, res["product_name"])
		assert_equal(purchase.product_image, res["product_image"])
		assert_equal(0, res["price"])
		assert_equal(purchase.currency, res["currency"])

		table_object_purchase = TableObjectPurchase.find_by(purchase: purchase, table_object: table_object)
		assert_not_nil(table_object_purchase)
		assert_equal(table_object_purchase.purchase_id, purchase.id)
		assert_equal(table_object_purchase.table_object_id, table_object.id)
	end

	# get_purchase
	it "should not get purchase without auth" do
		res = get_request("/v1/purchase/sadsaasd")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get purchase with dev that does not exist" do
		res = get_request(
			"/v1/purchase/asdasdasdsda",
			{Authorization: "asdasdasd,13wdfio23r8hifwe"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get purchase with invalid auth" do
		res = get_request(
			"/v1/purchase/sadasdsasda",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not get purchase with another dev than the first one" do
		res = get_request(
			"/v1/purchase/asdasasda",
			{Authorization: generate_auth(devs(:dav))}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get purchase that does not exist" do
		res = get_request(
			"/v1/purchase/ohahasfhoasfosfa",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should get purchase" do
		purchase = purchases(:snicketFirstBookMattPurchase)

		res = get_request(
			"/v1/purchase/#{purchase.uuid}",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 200
		
		assert_equal(purchase.id, res["id"])
		assert_equal(purchase.user_id, res["user_id"])
		assert_equal(purchase.uuid, res["uuid"])
		assert_equal(purchase.payment_intent_id, res["payment_intent_id"])
		assert_equal(purchase.provider_name, res["provider_name"])
		assert_equal(purchase.provider_image, res["provider_image"])
		assert_equal(purchase.product_name, res["product_name"])
		assert_equal(purchase.product_image, res["product_image"])
		assert_equal(purchase.price, res["price"])
		assert_equal(purchase.currency, res["currency"])
		assert_equal(purchase.completed, res["completed"])
	end

	# complete_purchase
	it "should not complete purchase without access token" do
		res = post_request("/v1/purchase/sdoshidf/complete")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not complete purchase with access token for session that does not exist" do
		res = post_request(
			"/v1/purchase/sjklsdsfld/complete",
			{Authorization: "asdasdasdasasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not complete purchase from another app than the website" do
		res = post_request(
			"/v1/purchase/sdfsdfsdf/complete",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not complete purchase that does not exist" do
		res = post_request(
			"/v1/purchase/sdfsdsfdfd/complete",
			{Authorization: sessions(:mattWebsiteSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not complete purchase that belongs to another user" do
		res = post_request(
			"/v1/purchase/#{purchases(:snicketFirstBookMattPurchase).uuid}/complete",
			{Authorization: sessions(:davWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not complete purchase that is already completed" do
		res = post_request(
			"/v1/purchase/#{purchases(:snicketFirstBookMattPurchase).uuid}/complete",
			{Authorization: sessions(:mattWebsiteSession).token}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_IS_ALREADY_COMPLETED, res["errors"][0]["code"])
	end

	it "should not complete purchase for table object that was already purchased" do
		res = post_request(
			"/v1/purchase/#{purchases(:snicketFirstBookMattPurchase2).uuid}/complete",
			{Authorization: sessions(:mattWebsiteSession).token}
		)
	
		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_ALREADY_PURCHASED_THIS_TABLE_OBJECT, res["errors"][0]["code"])
	end

	it "should not complete purchase if the user has no stripe customer" do
		res = post_request(
			"/v1/purchase/#{purchases(:snicketFirstBookCatoPurchase).uuid}/complete",
			{Authorization: sessions(:catoWebsiteSession).token}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_HAS_NO_PAYMENT_INFORMATION, res["errors"][0]["code"])
	end

	it "should complete purchase" do
		table_object = table_objects(:snicketSecondBook)
		table_object_price = table_object_prices(:snicketSecondBookEur)
		provider_name = "Lemony Snicket"
		provider_image = "https://api.pocketlib.app/author/sadasdasd/profile_image"
		product_name = "A Series of Unfortunate Events - Book the Second"
		product_image = "https://api.pocketlib.app/store/book/dfgsdfsdf/cover"
		currency = table_object_price.currency

		# Create a purchase
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:mattPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: provider_name,
				provider_image: provider_image,
				product_name: product_name,
				product_image: product_image,
				currency: currency,
				table_objects: [table_object.uuid]
			}
		)

		assert_response 201

		purchase = Purchase.find_by(id: res["id"])
		payment_intent_id = res["payment_intent_id"]

		res = post_request(
			"/v1/purchase/#{purchase.uuid}/complete",
			{Authorization: sessions(:mattWebsiteSession).token}
		)

		assert_response 200

		assert_equal(purchase.id, res["id"])
		assert_equal(purchase.user_id, res["user_id"])
		assert_equal(purchase.uuid, res["uuid"])
		assert_equal(purchase.payment_intent_id, res["payment_intent_id"])
		assert_equal(purchase.provider_name, res["provider_name"])
		assert_equal(purchase.provider_image, res["provider_image"])
		assert_equal(purchase.product_name, res["product_name"])
		assert_equal(purchase.product_image, res["product_image"])
		assert_equal(purchase.price, res["price"])
		assert_equal(purchase.currency, res["currency"])
		assert(res["completed"])

		# Check if the purchase was updated
		purchase = Purchase.find_by(id: purchase.id)
		assert_not_nil(purchase)
		assert(purchase.completed)

		# Get the payment intent
		payment_intent = Stripe::PaymentIntent.retrieve(purchase.payment_intent_id)
		assert_not_nil(payment_intent)
		assert_equal("succeeded", payment_intent["status"])
	end

	# delete_purchase
	it "should not delete purchase without access token" do
		res = delete_request("/v1/purchase/oioadasidasd")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not delete purchase with access token for session that does not exist" do
		res = delete_request(
			"/v1/purchase/hiosdhiosdfhiosfd",
			{Authorization: "asdasdasdasasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not delete purchase that does not exist" do
		res = delete_request(
			"/v1/purchase/ioashioashiodas",
			{Authorization: sessions(:mattPocketlibSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not delete purchase that belongs to another user" do
		res = delete_request(
			"/v1/purchase/#{purchases(:snicketFirstBookMattPurchase).uuid}",
			{Authorization: sessions(:snicketPocketlibSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not delete purchase whose table objects belong to another app" do
		res = delete_request(
			"/v1/purchase/#{purchases(:snicketFirstBookMattPurchase).uuid}",
			{Authorization: sessions(:snicketWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not delete purchase that is not free and already completed" do
		res = delete_request(
			"/v1/purchase/#{purchases(:snicketFirstBookMattPurchase).uuid}",
			{Authorization: sessions(:mattPocketlibSession).token}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PURCHASE_CANNOT_BE_DELETED, res["errors"][0]["code"])
	end

	it "should delete not completed purchase" do
		table_object = table_objects(:snicketSecondBook)
		table_object_price = table_object_prices(:snicketSecondBookEur)
		provider_name = "Lemony Snicket"
		provider_image = "https://api.pocketlib.app/author/sadasdasd/profile_image"
		product_name = "A Series of Unfortunate Events - Book the Second"
		product_image = "https://api.pocketlib.app/store/book/dfgsdfsdf/cover"
		currency = table_object_price.currency

		# Create a purchase
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:mattPocketlibSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: provider_name,
				provider_image: provider_image,
				product_name: product_name,
				product_image: product_image,
				currency: currency,
				table_objects: [table_object.uuid]
			}
		)

		assert_response 201

		purchase = Purchase.find_by(id: res["id"])
		payment_intent_id = res["payment_intent_id"]

		res = delete_request(
			"/v1/purchase/#{purchase.uuid}",
			{Authorization: sessions(:mattPocketlibSession).token}
		)

		assert_response 204

		# Check if the purchase was deleted
		purchase = Purchase.find_by(id: purchase.id)
		assert_nil(purchase)

		# Check if the payment intent was cancelled
		payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
		assert_not_nil(payment_intent)
		assert_equal("canceled", payment_intent["status"])
	end

	it "should delete free purchase" do
		table_object = table_objects(:sherlockTestFile)
		table_object_price = table_object_prices(:sherlockTestFileEur)
		provider_name = "sherlock"
		provider_image = "https://api.pocketlib.app/author/sadasdasd/profile_image"
		product_name = "Test file"
		product_image = "https://api.pocketlib.app/store/book/dfgsdfsdf/cover"
		currency = table_object_price.currency

		# Create a purchase
		res = post_request(
			"/v1/purchase",
			{Authorization: sessions(:davTestAppSession).token, 'Content-Type': 'application/json'},
			{
				provider_name: provider_name,
				provider_image: provider_image,
				product_name: product_name,
				product_image: product_image,
				currency: currency,
				table_objects: [table_object.uuid]
			}
		)

		assert_response 201

		purchase = Purchase.find_by(id: res["id"])

		res = delete_request(
			"/v1/purchase/#{purchase.uuid}",
			{Authorization: sessions(:davTestAppSession).token}
		)

		assert_response 204

		# Check if the purchase was deleted
		purchase = Purchase.find_by(id: purchase.id)
		assert_nil(purchase)
	end
end