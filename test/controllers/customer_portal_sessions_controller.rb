require "test_helper"

describe CustomerPortalSessionsController do
	setup do
		setup
	end

	# create_customer_portal_session
	it "should not create customer portal session without access token" do
		res = post_request("/v1/customer_portal_session")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create customer portal session with access token for session that does not exist" do
		res = post_request(
			"/v1/customer_portal_session",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create customer portal session from another app than the website" do
		res = post_request(
			"/v1/customer_portal_session",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create customer portal session if the user has no stripe customer" do
		res = post_request(
			"/v1/customer_portal_session",
			{Authorization: sessions(:catoWebsiteSession).token}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_HAS_NO_PAYMENT_INFORMATION, res["errors"][0]["code"])
	end

	it "should create customer portal session" do
		res = post_request(
			"/v1/customer_portal_session",
			{Authorization: sessions(:mattWebsiteSession).token}
		)

		assert_response 201
		assert_not_nil(res["session_url"])
	end
end