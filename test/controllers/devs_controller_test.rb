require "test_helper"

describe DevsController do
	setup do
		setup
	end

	# get_dev
	it "should not get dev without jwt" do
		res = get_request("/v1/dev")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get dev with invalid jwt" do
		res = get_request(
			"/v1/dev",
			{Authorization: "adasdasdasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not get dev from another app than the website" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = get_request(
			"/v1/dev",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get dev if the user is not a dev" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = get_request(
			"/v1/dev",
			{Authorization: jwt}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should get dev" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))
		sherlock = devs(:sherlock)
		notes = apps(:notes)
		cards = apps(:cards)
		website = apps(:website)

		res = get_request(
			"/v1/dev",
			{Authorization: jwt}
		)

		assert_response 200
		assert_equal(sherlock.id, res["id"])
		assert_equal(3, res["apps"].length)

		assert_equal(notes.id, res["apps"][0]["id"])
		assert_equal(notes.name, res["apps"][0]["name"])
		assert_equal(notes.description, res["apps"][0]["description"])
		assert_equal(notes.published, res["apps"][0]["published"])
		assert_equal(notes.web_link, res["apps"][0]["web_link"])
		assert_equal(notes.google_play_link, res["apps"][0]["google_play_link"])
		assert_equal(notes.microsoft_store_link, res["apps"][0]["microsoft_store_link"])

		assert_equal(cards.id, res["apps"][1]["id"])
		assert_equal(cards.name, res["apps"][1]["name"])
		assert_equal(cards.description, res["apps"][1]["description"])
		assert_equal(cards.published, res["apps"][1]["published"])
		assert_equal(cards.web_link, res["apps"][1]["web_link"])
		assert_equal(cards.google_play_link, res["apps"][1]["google_play_link"])
		assert_equal(cards.microsoft_store_link, res["apps"][1]["microsoft_store_link"])

		assert_equal(website.id, res["apps"][2]["id"])
		assert_equal(website.name, res["apps"][2]["name"])
		assert_equal(website.description, res["apps"][2]["description"])
		assert_equal(website.published, res["apps"][2]["published"])
		assert_nil(website.web_link, res["apps"][2]["web_link"])
		assert_nil(website.google_play_link, res["apps"][2]["google_play_link"])
		assert_nil(website.microsoft_store_link, res["apps"][2]["microsoft_store_link"])
	end
end