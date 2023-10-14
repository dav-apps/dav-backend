require "test_helper"

describe PurchasesController do
	setup do
		setup
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
		purchase = purchases(:snicketFirstBookCatoPurchase)
		payment_intent_id = purchase.payment_intent_id

		res = delete_request(
			"/v1/purchase/#{purchase.uuid}",
			{Authorization: sessions(:catoPocketlibSession).token}
		)

		assert_response 204

		# Check if the purchase was deleted
		purchase = Purchase.find_by(id: purchase.id)
		assert_nil(purchase)
	end

	# list_purchases_of_table_object
	it "should not list purchases of table object without auth" do
		res = get_request("/v2/table_objects/asdasdas/purchases")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not list purchases of table object with dev that does not exist" do
		res = get_request(
			"/v2/table_objects/asdasdas/purchases",
			{Authorization: "asdasdasd,13wdfio23r8hifwe"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not list purchases of table object with invalid auth" do
		res = get_request(
			"/v2/table_objects/asdasdas/purchases",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not list purchases of table object with another dev than the first one" do
		res = get_request(
			"/v2/table_objects/asdasdas/purchases",
			{Authorization: generate_auth(devs(:dav))}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not list purchases of table object that does not exist" do
		res = get_request(
			"/v2/table_objects/asdasdas/purchases",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should list purchases of table object" do
		table_object = table_objects(:snicketFirstBook)
		purchase = purchases(:snicketFirstBookMattPurchase)

		res = get_request(
			"/v2/table_objects/#{table_object.uuid}/purchases",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 200
		assert_equal(1, res["purchases"].count)
		
		res_purchase = res["purchases"][0]
		assert_equal(purchase.id, res_purchase["id"])
		assert_equal(purchase.user_id, res_purchase["user_id"])
		assert_equal(purchase.uuid, res_purchase["uuid"])
		assert_equal(purchase.payment_intent_id, res_purchase["payment_intent_id"])
		assert_equal(purchase.provider_name, res_purchase["provider_name"])
		assert_equal(purchase.provider_image, res_purchase["provider_image"])
		assert_equal(purchase.product_name, res_purchase["product_name"])
		assert_equal(purchase.product_image, res_purchase["product_image"])
		assert_equal(purchase.price, res_purchase["price"])
		assert_equal(purchase.currency, res_purchase["currency"])
		assert(res_purchase["completed"])
	end
end
