require "test_helper"

describe AppsController do
	setup do
		setup
	end

	# get_app
	it "should not get app without jwt" do
		res = get_request("/v1/app/1")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get app with invalid jwt" do
		res = get_request(
			"/v1/app/1",
			{Authorization: "sdaasdasdasdasdasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not get app from another app than the website" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = get_request(
			"/v1/app/1",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app that does not exist" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = get_request(
			"/v1/app/-123",
			{Authorization: jwt}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get app that belongs to another dev" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get app" do
		jwt = generate_jwt(sessions(:davWebsiteSession))
		app = apps(:pocketlib)

		res = get_request(
			"/v1/app/#{app.id}",
			{Authorization: jwt}
		)

		assert_response 200
		
		assert_equal(app.id, res["id"])
		assert_equal(app.dev_id, res["dev_id"])
		assert_equal(app.name, res["name"])
		assert_equal(app.description, res["description"])
		assert_equal(app.published, res["published"])
		assert_equal(app.web_link, res["web_link"])
		assert_equal(app.google_play_link, res["google_play_link"])
		assert_equal(app.microsoft_store_link, res["microsoft_store_link"])

		i = 0
		app.tables.each do |table|
			assert_equal(table.id, res["tables"][i]["id"])
			assert_equal(table.name, res["tables"[i]["name"]])
			i += 1
		end

		i = 0
		app.apis.each do |api|
			assert_equal(api.id, res["apis"][i]["id"])
			assert_equal(api.name, res["apis"][i]["name"])
			i += 1
		end
	end
end