require "test_helper"

describe ProvidersController do
	setup do
		setup
	end

	# create_provider
	it "should not create provider without access token" do
		res = post_request("/v1/provider")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create provider without Content-Type json" do
		res = post_request(
			"/v1/provider",
			{Authorization: "osdfosdosdfosf"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create provider with access token for session that does not exist" do
		res = post_request(
			"/v1/provider",
			{Authorization: "skdfnkosdfiosdf", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create provider from another app than the website" do
		res = post_request(
			"/v1/provider",
			{Authorization: sessions(:mattTestAppSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create provider without required properties" do
		res = post_request(
			"/v1/provider",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::COUNTRY_MISSING, res["errors"][0]["code"])
	end

	it "should not create provider with properties with wrong types" do
		res = post_request(
			"/v1/provider",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				country: 23.4
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::COUNTRY_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not create provider with not supported country" do
		res = post_request(
			"/v1/provider",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				country: "fr"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::COUNTRY_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create provider for user that already has a provider" do
		res = post_request(
			"/v1/provider",
			{Authorization: sessions(:snicketWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				country: "us"
			}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROVIDER_ALREADY_EXISTS, res["errors"][0]["code"])
	end

	it "should create provider" do
		matt = users(:matt)
		country = "DE"

		res = post_request(
			"/v1/provider",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				country: country
			}
		)

		assert_response 201

		assert_not_nil(res["id"])
		assert_equal(matt.id, res["user_id"])
		assert_not_nil(res["stripe_account_id"])

		# Check the provider
		provider = Provider.find_by(id: res["id"])
		assert_not_nil(provider)
		assert_equal(provider.id, res["id"])
		assert_equal(provider.user_id, res["user_id"])
		assert_equal(provider.stripe_account_id, res["stripe_account_id"])

		# Get the stripe account
		stripe_account = Stripe::Account.retrieve(provider.stripe_account_id)
		assert_not_nil(stripe_account)
		assert_equal(country, stripe_account.country)

		# Delete the stripe account
		Stripe::Account.delete(provider.stripe_account_id)
	end
end