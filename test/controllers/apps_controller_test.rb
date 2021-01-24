require "test_helper"

describe AppsController do
	setup do
		setup
	end

	# create_app
	it "should not create app without access token" do
		res = post_request("/v1/app")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create app without Content-Type json" do
		res = post_request(
			"/v1/app",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create app with access token for session that does not exist" do
		res = post_request(
			"/v1/app",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create app from another app than the website" do
		res = post_request(
			"/v1/app",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create app without required properties" do
		res = post_request(
			"/v1/app",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DESCRIPTION_MISSING, res["errors"][1]["code"])
	end

	it "should not create app with properties with wrong types" do
		res = post_request(
			"/v1/app",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				name: true,
				description: 1.2
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DESCRIPTION_WRONG_TYPE, res["errors"][1]["code"])
	end

	it "should not create app with too short properties" do
		res = post_request(
			"/v1/app",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
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

	it "should not create app with too long properties" do
		res = post_request(
			"/v1/app",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				name: "a" * 250,
				description: "a" * 250
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DESCRIPTION_TOO_LONG, res["errors"][1]["code"])
	end

	it "should not create app if the user is not a dev" do
		res = post_request(
			"/v1/app",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				name: "TestApp",
				description: "This is a test app"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should create app" do
		name = "TestApp"
		description = "This is a test app"

		res = post_request(
			"/v1/app",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				name: name,
				description: description
			}
		)

		assert_response 201

		assert_not_nil(res["id"])
		assert_equal(devs(:sherlock).id, res["dev_id"])
		assert_equal(name, res["name"])
		assert_equal(description, res["description"])
		assert(!res["published"])
		assert_nil(res["web_link"])
		assert_nil(res["google_play_link"])
		assert_nil(res["microsoft_store_link"])

		app = App.find_by(id: res["id"])
		assert_not_nil(app)
		assert_equal(app.id, res["id"])
		assert_equal(app.dev_id, res["dev_id"])
		assert_equal(app.name, res["name"])
		assert_equal(app.description, res["description"])
		assert(!app.published)
		assert_nil(app.web_link)
		assert_nil(app.google_play_link)
		assert_nil(app.microsoft_store_link)
	end

	# get_apps
	it "should get apps" do
		cards = apps(:cards)
		notes = apps(:notes)

		res = get_request("/v1/apps")

		assert_response 200
		assert_equal(2, res["apps"].length)

		assert_equal(notes.id, res["apps"][0]["id"])
		assert_equal(notes.dev_id, res["apps"][0]["dev_id"])
		assert_equal(notes.name, res["apps"][0]["name"])
		assert_equal(notes.description, res["apps"][0]["description"])
		assert_equal(notes.published, res["apps"][0]["published"])
		assert_equal(notes.web_link, res["apps"][0]["web_link"])
		assert_equal(notes.google_play_link, res["apps"][0]["google_play_link"])
		assert_equal(notes.microsoft_store_link, res["apps"][0]["microsoft_store_link"])

		assert_equal(cards.id, res["apps"][1]["id"])
		assert_equal(cards.dev_id, res["apps"][1]["dev_id"])
		assert_equal(cards.name, res["apps"][1]["name"])
		assert_equal(cards.description, res["apps"][1]["description"])
		assert_equal(cards.published, res["apps"][1]["published"])
		assert_equal(cards.web_link, res["apps"][1]["web_link"])
		assert_equal(cards.google_play_link, res["apps"][1]["google_play_link"])
		assert_equal(cards.microsoft_store_link, res["apps"][1]["microsoft_store_link"])
	end

	# get_app
	it "should not get app without access token" do
		res = get_request("/v1/app/1")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get app with access token for session that does not exist" do
		res = get_request(
			"/v1/app/1",
			{Authorization: "sdaasdasdasdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get app from another app than the website" do
		res = get_request(
			"/v1/app/1",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app that does not exist" do
		res = get_request(
			"/v1/app/-123",
			{Authorization: sessions(:sherlockWebsiteSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get app that belongs to another dev" do
		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}",
			{Authorization: sessions(:sherlockWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get app" do
		app = apps(:pocketlib)

		res = get_request(
			"/v1/app/#{app.id}",
			{Authorization: sessions(:davWebsiteSession).token}
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
	it "should not update app without access token" do
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

	it "should not update app with access token for session that does not exist" do
		res = put_request(
			"/v1/app/1",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update app from another app than the website" do
		res = get_request(
			"/v1/app/1",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update app that does not exist" do
		res = put_request(
			"/v1/app/-123",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update app that belongs to another dev" do
		res = put_request(
			"/v1/app/#{apps(:pocketlib).id}",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update app with properties with wrong types" do
		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = put_request(
			"/v1/app/#{apps(:cards).id}",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
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
		app = apps(:cards)
		name = "Updated name"
		description = "Updated description"
		published = false
		web_link = "https://cards.app"
		google_play_link = "https://play.google.com/cards"
		microsoft_store_link = "https://store.microsoft.com/cards"

		res = put_request(
			"/v1/app/#{app.id}",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
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
		app = apps(:cards)

		res = put_request(
			"/v1/app/#{app.id}",
			{Authorization: sessions(:sherlockWebsiteSession).token, 'Content-Type': 'application/json'},
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