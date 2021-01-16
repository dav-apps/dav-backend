require "test_helper"

describe AppUsersController do
	setup do
		setup
	end

	# get_app_users
	it "should not get app users without jwt" do
		res = get_request("/v1/app/1/users")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get app users with invalid jwt" do
		res = get_request(
			"/v1/app/1/users",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not get app users from another app than the website" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = get_request(
			"/v1/app/1/users",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app users for the app of another dev" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}/users",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app users if the user is not a dev" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}/users",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get app users" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))
		matt_cards = app_users(:mattCards)
		dav_cards = app_users(:davCards)

		res = get_request(
			"/v1/app/#{apps(:cards).id}/users",
			{Authorization: jwt}
		)

		assert_response 200
		assert_equal(2, res["app_users"].length)

		assert_equal(dav_cards.user_id, res["app_users"][0]["user_id"])
		assert_equal(dav_cards.created_at.to_i, DateTime.parse(res["app_users"][0]["created_at"]).to_i)

		assert_equal(matt_cards.user_id, res["app_users"][1]["user_id"])
		assert_equal(matt_cards.created_at.to_i, DateTime.parse(res["app_users"][1]["created_at"]).to_i)
	end
end