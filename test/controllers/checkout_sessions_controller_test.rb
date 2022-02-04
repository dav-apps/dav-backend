require "test_helper"

describe UsersController do
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

	it "should not create checkout session with too short properties" do
		res = post_request(
			"/v1/checkout_session",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				plan: 1,
				success_url: "as",
				cancel_url: "qw"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::SUCCESS_URL_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::CANCEL_URL_TOO_SHORT, res["errors"][1]["code"])
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
		assert_equal(session.success_url, success_url)
		assert_equal(session.cancel_url, cancel_url)

		Stripe::Customer.delete(customer.id)
	end
end