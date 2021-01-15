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

	# update_app
	it "should not update app without jwt" do
		res = put_request("/v1/app/1")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not update app without Content-Type json" do
		res = put_request(
			"/v1/app/1",
			{Authorization: "asdasasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not update app with invalid jwt" do
		res = put_request(
			"/v1/app/1",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not update app from another app than the website" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = get_request(
			"/v1/app/1",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update app that does not exist" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = put_request(
			"/v1/app/-123",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update app that belongs to another dev" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = put_request(
			"/v1/app/#{apps(:pocketlib).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update app with properties with wrong types" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				name: true,
				description: 123,
				published: "Hello World",
				web_link: false,
				google_play_link: 41.2,
				microsoft_store_link: true
			}
		)

		assert_response 400
		assert_equal(6, res["errors"].length)
		assert_equal(ErrorCodes::NAME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DESCRIPTION_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PUBLISHED_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::WEB_LINK_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::GOOGLE_PLAY_LINK_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCodes::MICROSOFT_STORE_LINK_WRONG_TYPE, res["errors"][5]["code"])
	end

	it "should not update app with too short properties" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				name: "a",
				description: "a"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DESCRIPTION_TOO_SHORT, res["errors"][1]["code"])
	end

	it "should not update app with too long properties" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				name: "a" * 300,
				description: "a" * 300,
				web_link: "a" * 200,
				google_play_link: "a" * 200,
				microsoft_store_link: "a" * 200
			}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DESCRIPTION_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::WEB_LINK_TOO_LONG, res["errors"][2]["code"])
		assert_equal(ErrorCodes::GOOGLE_PLAY_LINK_TOO_LONG, res["errors"][3]["code"])
		assert_equal(ErrorCodes::MICROSOFT_STORE_LINK_TOO_LONG, res["errors"][4]["code"])
	end

	it "should not update app with invalid properties" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				web_link: "aaaaaaa",
				google_play_link: "aaaaaaa",
				microsoft_store_link: "aaaaaaaa"
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::WEB_LINK_INVALID, res["errors"][0]["code"])
		assert_equal(ErrorCodes::GOOGLE_PLAY_LINK_INVALID, res["errors"][1]["code"])
		assert_equal(ErrorCodes::MICROSOFT_STORE_LINK_INVALID, res["errors"][2]["code"])
	end

	it "should update app" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))
		app = apps(:cards)
		name = "Updated name"
		description = "Updated description"
		published = false
		web_link = "https://cards.app"
		google_play_link = "https://play.google.com/cards"
		microsoft_store_link = "https://store.microsoft.com/cards"

		res = put_request(
			"/v1/app/#{app.id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				name: name,
				description: description,
				published: published,
				web_link: web_link,
				google_play_link: google_play_link,
				microsoft_store_link: microsoft_store_link
			}
		)

		assert_response 200

		assert_equal(app.id, res["id"])
		assert_equal(app.dev_id, res["dev_id"])
		assert_equal(name, res["name"])
		assert_equal(description, res["description"])
		assert_equal(published, res["published"])
		assert_equal(web_link, res["web_link"])
		assert_equal(google_play_link, res["google_play_link"])
		assert_equal(microsoft_store_link, res["microsoft_store_link"])

		app = App.find_by(id: app.id)
		assert_not_nil(app)
		assert_equal(app.id, res["id"])
		assert_equal(app.dev_id, res["dev_id"])
		assert_equal(app.name, res["name"])
		assert_equal(app.description, res["description"])
		assert_equal(app.published, res["published"])
		assert_equal(app.web_link, res["web_link"])
		assert_equal(app.google_play_link, res["google_play_link"])
		assert_equal(app.microsoft_store_link, res["microsoft_store_link"])
	end

	it "should update app and remove links with empty values" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))
		app = apps(:cards)

		res = put_request(
			"/v1/app/#{app.id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				web_link: "",
				google_play_link: "",
				microsoft_store_link: ""
			}
		)

		assert_response 200

		assert_equal(app.id, res["id"])
		assert_equal(app.dev_id, res["dev_id"])
		assert_equal(app.name, res["name"])
		assert_equal(app.description, res["description"])
		assert_equal(app.published, res["published"])
		assert_nil(res["web_link"])
		assert_nil(res["google_play_link"])
		assert_nil(res["microsoft_store_link"])

		app = App.find_by(id: app.id)
		assert_not_nil(app)
		assert_equal(app.id, res["id"])
		assert_equal(app.dev_id, res["dev_id"])
		assert_equal(app.name, res["name"])
		assert_equal(app.description, res["description"])
		assert_equal(app.published, res["published"])
		assert_nil(app.web_link)
		assert_nil(app.google_play_link)
		assert_nil(app.microsoft_store_link)
	end
end