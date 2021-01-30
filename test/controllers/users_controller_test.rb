require "test_helper"

describe UsersController do
	setup do
		setup
	end

	# signup
	it "should not signup without auth" do
		res = post_request("/v1/signup")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not signup without Content-Type json" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not signup without required properties" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::FIRST_NAME_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PASSWORD_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCodes::APP_ID_MISSING, res["errors"][3]["code"])
		assert_equal(ErrorCodes::API_KEY_MISSING, res["errors"][4]["code"])
	end

	it "should not signup with properties with wrong types" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: 123,
				first_name: true,
				password: 12.34,
				app_id: false,
				api_key: 12345
			}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::FIRST_NAME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PASSWORD_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][4]["code"])
	end

	it "should not signup with optional properties with wrong types" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: false,
				first_name: true,
				password: 123456,
				app_id: "asdsad",
				api_key: 12.423,
				device_name: true,
				device_type: 123,
				device_os: false
			}
		)

		assert_response 400
		assert_equal(8, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::FIRST_NAME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PASSWORD_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCodes::DEVICE_NAME_WRONG_TYPE, res["errors"][5]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_WRONG_TYPE, res["errors"][6]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_WRONG_TYPE, res["errors"][7]["code"])
	end

	it "should not signup with too short properties" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "a",
				password: "1234",
				app_id: 1,
				api_key: "asdasdasd"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::FIRST_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_TOO_SHORT, res["errors"][1]["code"])
	end

	it "should not signup with too short optional properties" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "a",
				password: "a",
				app_id: 1,
				api_key: "asdasdasd",
				device_name: "a",
				device_type: "a",
				device_os: "a"
			}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::FIRST_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_TOO_SHORT, res["errors"][1]["code"])
		assert_equal(ErrorCodes::DEVICE_NAME_TOO_SHORT, res["errors"][2]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_TOO_SHORT, res["errors"][3]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_TOO_SHORT, res["errors"][4]["code"])
	end

	it "should not signup with too long properties" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "a" * 30,
				password: "a" * 30,
				app_id: 1,
				api_key: "asdasdasd"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::FIRST_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_TOO_LONG, res["errors"][1]["code"])
	end

	it "should not signup with too long optional properties" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "a" * 30,
				password: "a" * 30,
				app_id: 1,
				api_key: "asdasdasd",
				device_name: "a" * 50,
				device_type: "a" * 50,
				device_os: "a" * 50
			}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::FIRST_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::DEVICE_NAME_TOO_LONG, res["errors"][2]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_TOO_LONG, res["errors"][3]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_TOO_LONG, res["errors"][4]["code"])
	end

	it "should not signup with email that is already in use" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: "dav@dav-apps.tech",
				first_name: "Testuser",
				password: "123123123",
				app_id: 1,
				api_key: "asdasdasd"
			}
		)

		assert_response 409
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_ALREADY_TAKEN, res["errors"][0]["code"])
	end

	it "should not signup with invalid email" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'},
			{
				email: "testemail",
				first_name: "Testuser",
				password: "123123123",
				app_id: 1,
				api_key: "asdasdasd"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_INVALID, res["errors"][0]["code"])
	end

	it "should not signup with dev that does not exist" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "Testuser",
				password: "123123123",
				app_id: 1,
				api_key: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not signup with invalid auth" do
		res = post_request(
			"/v1/signup",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "Testuser",
				password: "123123123",
				app_id: 1,
				api_key: "asdasdasd"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not signup with another dev than the first one" do
		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "Testuser",
				password: "123123123",
				app_id: 1,
				api_key: "asdasdasd"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not signup for app that does not exist" do
		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "Testuser",
				password: "123123123",
				app_id: -256,
				api_key: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not signup with api key for dev that does not exist" do
		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "Testuser",
				password: "123123123",
				app_id: apps(:cards).id,
				api_key: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not signup for app that does not belong to the dev" do
		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				first_name: "Testuser",
				password: "123123123",
				app_id: apps(:cards).id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should signup from website" do
		email = "test@example.com"
		first_name = "Testuser"
		app = apps(:website)

		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: email,
				first_name: first_name,
				password: "123123123",
				app_id: app.id,
				api_key: devs(:sherlock).api_key
			}
		)

		assert_response 201

		# Check the response
		assert_not_nil(res["user"]["id"])
		assert_equal(email, res["user"]["email"])
		assert_equal(first_name, res["user"]["first_name"])
		assert(!res["user"]["confirmed"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])
		assert_equal(0, res["user"]["plan"])
		
		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.used_storage)
		assert_equal(0, user.plan)

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)
		
		assert_nil(res["website_access_token"])
	end

	it "should signup from app" do
		email = "test@example.com"
		first_name = "Testuser"
		app = apps(:cards)

		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: email,
				first_name: first_name,
				password: "123123123",
				app_id: app.id,
				api_key: devs(:sherlock).api_key
			}
		)

		assert_response 201

		# Check the response
		assert_not_nil(res["user"]["id"])
		assert_equal(email, res["user"]["email"])
		assert_equal(first_name, res["user"]["first_name"])
		assert(!res["user"]["confirmed"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])
		assert_equal(0, res["user"]["plan"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.used_storage)
		assert_equal(0, user.plan)

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)

		# Check the website session
		website_session = Session.find_by(token: res["website_access_token"])
		assert_not_nil(website_session)
		assert_equal(user, website_session.user)
		assert_equal(apps(:website), website_session.app)
		assert_nil(website_session.device_name)
		assert_nil(website_session.device_type)
		assert_nil(website_session.device_os)
	end

	it "should signup from app of another dev" do
		email = "test@example.com"
		first_name = "Testuser"
		app = apps(:testApp)

		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: email,
				first_name: first_name,
				password: "123123123",
				app_id: app.id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 201

		# Check the response
		assert_not_nil(res["user"]["id"])
		assert_equal(email, res["user"]["email"])
		assert_equal(first_name, res["user"]["first_name"])
		assert(!res["user"]["confirmed"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])
		assert_equal(0, res["user"]["plan"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.used_storage)
		assert_equal(0, user.plan)

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)

		# Check the website session
		website_session = Session.find_by(token: res["website_access_token"])
		assert_not_nil(website_session)
		assert_equal(user, website_session.user)
		assert_equal(apps(:website), website_session.app)
		assert_nil(website_session.device_name)
		assert_nil(website_session.device_type)
		assert_nil(website_session.device_os)
	end

	it "should signup from website with device info" do
		email = "test@example.com"
		first_name = "Testuser"
		app = apps(:website)
		device_name = "Surface Phone"
		device_type = "Dual-Screen"
		device_os = "Andromeda"

		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: email,
				first_name: first_name,
				password: "123123123",
				app_id: app.id,
				api_key: devs(:sherlock).api_key,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			}
		)

		assert_response 201

		# Check the response
		assert_not_nil(res["user"]["id"])
		assert_equal(email, res["user"]["email"])
		assert_equal(first_name, res["user"]["first_name"])
		assert(!res["user"]["confirmed"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])
		assert_equal(0, res["user"]["plan"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.used_storage)
		assert_equal(0, user.plan)

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)
		
		assert_nil(res["website_access_token"])
	end

	it "should signup from app with device info" do
		email = "test@example.com"
		first_name = "Testuser"
		app = apps(:cards)
		device_name = "Surface Phone"
		device_type = "Dual-Screen"
		device_os = "Andromeda"

		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: email,
				first_name: first_name,
				password: "123123123",
				app_id: app.id,
				api_key: devs(:sherlock).api_key,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			}
		)

		assert_response 201

		# Check the response
		assert_not_nil(res["user"]["id"])
		assert_equal(email, res["user"]["email"])
		assert_equal(first_name, res["user"]["first_name"])
		assert(!res["user"]["confirmed"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])
		assert_equal(0, res["user"]["plan"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.used_storage)
		assert_equal(0, user.plan)

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)

		# Check the website session
		website_session = Session.find_by(token: res["website_access_token"])
		assert_not_nil(website_session)
		assert_equal(user, website_session.user)
		assert_equal(apps(:website), website_session.app)
		assert_equal(device_name, website_session.device_name)
		assert_equal(device_type, website_session.device_type)
		assert_equal(device_os, website_session.device_os)
	end

	it "should signup from app of another dev with device info" do
		email = "test@example.com"
		first_name = "Testuser"
		app = apps(:testApp)
		device_name = "Surface Phone"
		device_type = "Dual-Screen"
		device_os = "Andromeda"

		res = post_request(
			"/v1/signup",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: email,
				first_name: first_name,
				password: "123123123",
				app_id: app.id,
				api_key: devs(:dav).api_key,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			}
		)

		assert_response 201

		# Check the response
		assert_not_nil(res["user"]["id"])
		assert_equal(email, res["user"]["email"])
		assert_equal(first_name, res["user"]["first_name"])
		assert(!res["user"]["confirmed"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])
		assert_equal(0, res["user"]["plan"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.used_storage)
		assert_equal(0, user.plan)

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)

		# Check the website session
		website_session = Session.find_by(token: res["website_access_token"])
		assert_not_nil(website_session)
		assert_equal(user, website_session.user)
		assert_equal(apps(:website), website_session.app)
		assert_equal(device_name, website_session.device_name)
		assert_equal(device_type, website_session.device_type)
		assert_equal(device_os, website_session.device_os)
	end

	# get_users
	it "should not get users without access token" do
		res = get_request("/v1/users")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get users with access token for session that does not exist" do
		res = get_request(
			"/v1/users",
			{Authorization: "asdasdjsgoljsdfsfd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get users from another app than the website" do
		res = get_request(
			"/v1/users",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get users with another dev than the first one" do
		res = get_request(
			"/v1/users",
			{Authorization: sessions(:davWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get users" do
		sherlock = users(:sherlock)
		cato = users(:cato)
		dav = users(:dav)
		matt = users(:matt)

		res = get_request(
			"/v1/users",
			{Authorization: sessions(:sherlockWebsiteSession).token}
		)

		assert_response 200
		assert_equal(4, res["users"].length)

		assert_equal(sherlock.id, res["users"][0]["id"])
		assert_equal(sherlock.confirmed, res["users"][0]["confirmed"])
		assert_equal(sherlock.last_active, res["users"][0]["last_active"])
		assert_equal(sherlock.plan, res["users"][0]["plan"])
		assert_equal(sherlock.created_at.to_i, DateTime.parse(res["users"][0]["created_at"]).to_i)

		assert_equal(cato.id, res["users"][1]["id"])
		assert_equal(cato.confirmed, res["users"][1]["confirmed"])
		assert_equal(cato.last_active, res["users"][1]["last_active"])
		assert_equal(cato.plan, res["users"][1]["plan"])
		assert_equal(cato.created_at.to_i, DateTime.parse(res["users"][1]["created_at"]).to_i)

		assert_equal(dav.id, res["users"][2]["id"])
		assert_equal(dav.confirmed, res["users"][2]["confirmed"])
		assert_equal(dav.last_active, res["users"][2]["last_active"])
		assert_equal(dav.plan, res["users"][2]["plan"])
		assert_equal(dav.created_at.to_i, DateTime.parse(res["users"][2]["created_at"]).to_i)

		assert_equal(matt.id, res["users"][3]["id"])
		assert_equal(matt.confirmed, res["users"][3]["confirmed"])
		assert_equal(matt.last_active, res["users"][3]["last_active"])
		assert_equal(matt.plan, res["users"][3]["plan"])
		assert_equal(matt.created_at.to_i, DateTime.parse(res["users"][3]["created_at"]).to_i)
	end

	# get_user
	it "should not get user without access token" do
		res = get_request("/v1/user")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get user with access token for session that does not exist" do
		res = get_request(
			"/v1/user",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should get user" do
		res = get_request(
			"/v1/user",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200

		matt = users(:matt)
		assert_equal(matt.id, res["id"])
		assert_equal(matt.email, res["email"])
		assert_equal(matt.first_name, res["first_name"])
		assert_equal(matt.confirmed, res["confirmed"])
		assert_equal(get_total_storage(matt.plan, matt.confirmed), res["total_storage"])
		assert_equal(matt.used_storage, res["used_storage"])
		assert_equal(matt.plan, res["plan"])
		assert(!res["dev"])
		assert(!res["provider"])

		assert_nil(res["stripe_customer_id"])
		assert_nil(res["subscription_status"])
		assert_nil(res["period_end"])
		assert_nil(res["apps"])
	end

	it "should get user with additional information with website session" do
		res = get_request(
			"/v1/user",
			{Authorization: sessions(:davWebsiteSession).token}
		)

		assert_response 200

		dav = users(:dav)
		assert_equal(dav.id, res["id"])
		assert_equal(dav.email, res["email"])
		assert_equal(dav.first_name, res["first_name"])
		assert_equal(dav.confirmed, res["confirmed"])
		assert_equal(get_total_storage(dav.plan, dav.confirmed), res["total_storage"])
		assert_equal(dav.used_storage, res["used_storage"])
		assert_nil(res["stripe_customer_id"])
		assert_equal(dav.plan, res["plan"])
		assert_equal(dav.subscription_status, res["subscription_status"])
		assert_nil(res["period_end"])
		assert(res["dev"])
		assert(!res["provider"])

		cards = apps(:cards)
		assert_equal(1, res["apps"].length)
		assert_equal(cards.id, res["apps"][0]["id"])
		assert_equal(cards.name, res["apps"][0]["name"])
		assert_equal(cards.description, res["apps"][0]["description"])
		assert_equal(cards.published, res["apps"][0]["published"])
		assert_equal(cards.web_link, res["apps"][0]["web_link"])
		assert_equal(cards.google_play_link, res["apps"][0]["google_play_link"])
		assert_equal(cards.microsoft_store_link, res["apps"][0]["microsoft_store_link"])
		assert_equal(0, res["apps"][0]["used_storage"])
	end

	# update_user
	it "should not update user without access token" do
		res = put_request("/v1/user")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not update user without Content-Type json" do
		res = put_request(
			"/v1/user",
			{Authorization: "asdsdasdasdasda"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not update user with access token for session that does not exist" do
		res = put_request(
			"/v1/user",
			{Authorization: "asdsdasdasdasda", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update user from another app than the website" do
		res = put_request(
			"/v1/user",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update user with properties with wrong types" do
		res = put_request(
			"/v1/user",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				email: true,
				first_name: 23.4,
				password: false
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::FIRST_NAME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::PASSWORD_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not update user with email that is already in use" do
		res = put_request(
			"/v1/user",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				email: users(:sherlock).email
			}
		)

		assert_response 409
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_ALREADY_TAKEN, res["errors"][0]["code"])
	end

	it "should not update user with invalid email" do
		res = put_request(
			"/v1/user",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				email: "hello world"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_INVALID, res["errors"][0]["code"])
	end

	it "should not update user with too short properties" do
		res = put_request(
			"/v1/user",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				first_name: "a",
				password: "a"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::FIRST_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_TOO_SHORT, res["errors"][1]["code"])
	end

	it "should not update user with too long properties" do
		res = put_request(
			"/v1/user",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				first_name: "a" * 200,
				password: "a" * 200
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::FIRST_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_TOO_LONG, res["errors"][1]["code"])
	end

	it "should update user" do
		matt = users(:matt)
		email = "updatedemail@dav-apps.tech"
		first_name = "updated name"
		password = "updated password"

		res = put_request(
			"/v1/user",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				email: email,
				first_name: first_name,
				password: password
			}
		)

		assert_response 200

		assert_equal(matt.id, res["id"])
		assert_equal(matt.email, res["email"])
		assert_equal(first_name, res["first_name"])
		assert_equal(matt.confirmed, res["confirmed"])
		assert_equal(get_total_storage(matt.plan, matt.confirmed), res["total_storage"])
		assert_equal(matt.used_storage, res["used_storage"])
		assert_equal(matt.stripe_customer_id, res["stripe_customer_id"])
		assert_equal(matt.plan, res["plan"])
		assert_equal(matt.subscription_status, res["subscription_status"])
		assert_nil(res["period_end"])
		assert(!res["dev"])
		assert(!res["provider"])

		# Check if the user was updated
		matt = User.find_by(id: matt.id)
		assert_not_nil(matt)
		assert_equal(first_name, matt.first_name)
		assert_equal(email, matt.new_email)
		assert(BCrypt::Password.new(matt.new_password) == password)

		assert_not_nil(matt.email_confirmation_token)
		assert_not_nil(matt.password_confirmation_token)
	end

	# set_profile_image_of_user
	it "should not set profile image of user without access token" do
		res = put_request("/v1/user/profile_image")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set profile image of user with not supported content type" do
		res = put_request(
			"/v1/user/profile_image",
			{Authorization: "dafsgiosdfjposdf", 'Content-Type': 'application/json'}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set profile image of user with access token for session that does not exist" do
		res = put_request(
			"/v1/user/profile_image",
			{Authorization: "sdsdjsdfsdfsdfsdf", 'Content-Type': 'image/png'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set profile image of user from another app than the website" do
		res = put_request(
			"/v1/user/profile_image",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'image/png'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not set profile image of user with invalid image" do
		res = put_request(
			"/v1/user/profile_image",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'image/png'},
			"Hello World",
			false
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::IMAGE_FILE_INVALID, res["errors"][0]["code"])
	end

	it "should not set profile image of user with content type that does not match the image type" do
		file_content = File.open("test/fixtures/files/test.gif", "rb").read

		res = put_request(
			"/v1/user/profile_image",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'image/png'},
			file_content,
			false
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_DOES_NOT_MATCH_FILE_TYPE, res["errors"][0]["code"])
	end

	it "should not set profile image of user with too large image file" do
		file_content = File.open("test/fixtures/files/usb-logo.png", "rb").read

		res = put_request(
			"/v1/user/profile_image",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'image/png'},
			file_content,
			false
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::IMAGE_FILE_TOO_LARGE, res["errors"][0]["code"])
	end

	it "should set profile image of user" do
		matt = users(:matt)
		file_content = File.open("test/fixtures/files/favicon.png", "rb").read

		res = put_request(
			"/v1/user/profile_image",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'image/png'},
			file_content,
			false
		)

		assert_response 200

		assert_equal(matt.id, res["id"])
		assert_equal(matt.email, res["email"])
		assert_equal(matt.first_name, res["first_name"])
		assert_equal(matt.confirmed, res["confirmed"])
		assert_equal(get_total_storage(matt.plan, matt.confirmed), res["total_storage"])
		assert_equal(matt.used_storage, res["used_storage"])
		assert_equal(matt.stripe_customer_id, res["stripe_customer_id"])
		assert_equal(matt.plan, res["plan"])
		assert_equal(matt.subscription_status, res["subscription_status"])
		assert_nil(res["period_end"])
		assert(!res["dev"])
		assert(!res["provider"])

		# Check the UserProfileImage
		user_profile_image = UserProfileImage.find_by(user_id: matt.id)
		assert_not_nil(user_profile_image)
		assert_equal(matt.id, user_profile_image.user_id)
		assert_equal("png", user_profile_image.ext)
		assert_equal("image/png", user_profile_image.mime_type)
		assert_not_nil(user_profile_image.etag)
	end

	it "should set profile image of user and update existing UserProfileImage" do
		cato = users(:cato)
		user_profile_image = user_profile_images(:catoProfileImage)
		old_etag = user_profile_image.etag
		file_content = File.open("test/fixtures/files/favicon.png", "rb").read

		res = put_request(
			"/v1/user/profile_image",
			{Authorization: sessions(:catoWebsiteSession).token, 'Content-Type': 'image/png'},
			file_content,
			false
		)

		assert_response 200

		assert_equal(cato.id, res["id"])
		assert_equal(cato.email, res["email"])
		assert_equal(cato.first_name, res["first_name"])
		assert_equal(cato.confirmed, res["confirmed"])
		assert_equal(get_total_storage(cato.plan, cato.confirmed), res["total_storage"])
		assert_equal(cato.used_storage, res["used_storage"])
		assert_nil(res["stripe_customer_id"])
		assert_equal(cato.plan, res["plan"])
		assert_equal(cato.subscription_status, res["subscription_status"])
		assert_nil(res["period_end"])
		assert(!res["dev"])
		assert(!res["provider"])

		# Check the UserProfileImage
		user_profile_image = UserProfileImage.find_by(id: user_profile_image.id)
		assert_not_nil(user_profile_image)
		assert_equal(cato.id, user_profile_image.user_id)
		assert_equal("png", user_profile_image.ext)
		assert_equal("image/png", user_profile_image.mime_type)
		assert_not_nil(user_profile_image.etag)
		assert_not_equal(old_etag, user_profile_image.etag)
	end

	# send_confirmation_email
	it "should not send confirmation email without auth" do
		res = post_request("/v1/user/1/send_confirmation_email")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not send confirmation email with dev that does not exist" do
		res = post_request(
			"/v1/user/1/send_confirmation_email",
			{Authorization: "asdasdasd,asdwfqfwafasf"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not send confirmation email with invalid auth" do
		res = post_request(
			"/v1/user/1/send_confirmation_email",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not send confirmation email with another dev than the first one" do
		res = post_request(
			"/v1/user/1/send_confirmation_email",
			{Authorization: generate_auth(devs(:dav))}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not send confirmation email for user that does not exist" do
		res = post_request(
			"/v1/user/-123/send_confirmation_email",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should send confirmation email" do
		matt = users(:matt)

		res = post_request(
			"/v1/user/#{matt.id}/send_confirmation_email",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 204

		# Check if the user was updated
		matt = User.find_by(id: matt.id)
		assert_not_nil(matt.email_confirmation_token)
	end

	# send_password_reset_email
	it "should not send password reset email without auth" do
		res = post_request("/v1/user/1/send_password_reset_email")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not send password reset email with dev that does not exist" do
		res = post_request(
			"/v1/user/1/send_password_reset_email",
			{Authorization: "asdasdasd,asdwfqfwafasf"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not send password reset email with invalid auth" do
		res = post_request(
			"/v1/user/1/send_password_reset_email",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not send password reset email with another dev than the first one" do
		res = post_request(
			"/v1/user/1/send_password_reset_email",
			{Authorization: generate_auth(devs(:dav))}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not send password reset email for user that does not exist" do
		res = post_request(
			"/v1/user/1/send_password_reset_email",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should send password reset email" do
		matt = users(:matt)

		res = post_request(
			"/v1/user/#{matt.id}/send_password_reset_email",
			{Authorization: generate_auth(devs(:sherlock))}
		)

		assert_response 204

		# Check if the user was updated
		matt = User.find_by(id: matt.id)
		assert_not_nil(matt.password_confirmation_token)
	end

	# confirm_user
	it "should not confirm user without auth" do
		res = post_request("/v1/user/1/confirm")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not confirm user without Content-Type json" do
		res = post_request(
			"/v1/user/1/confirm",
			{Authorization: "asdasasdsad"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not confirm user without required properties" do
		res = post_request(
			"/v1/user/1/confirm",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_CONFIRMATION_TOKEN_MISSING, res["errors"][0]["code"])
	end

	it "should not confirm user with properties with wrong types" do
		res = post_request(
			"/v1/user/1/confirm",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: 12.3
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_CONFIRMATION_TOKEN_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not confirm user with dev that does not exist" do
		res = post_request(
			"/v1/user/1/confirm",
			{Authorization: "asdasdasd,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not confirm user with invalid auth" do
		res = post_request(
			"/v1/user/1/confirm",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasdasd"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not confirm user with another dev than the first one" do
		res = post_request(
			"/v1/user/1/confirm",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasd"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not confirm user that does not exist" do
		res = post_request(
			"/v1/user/-123/confirm",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not confirm user that is already confirmed" do
		res = post_request(
			"/v1/user/#{users(:matt).id}/confirm",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asasdasdasd"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_IS_ALREADY_CONFIRMED, res["errors"][0]["code"])
	end

	it "should not confirm user with incorrect email confirmation token" do
		cato = users(:cato)

		res = post_request(
			"/v1/user/#{cato.id}/confirm",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "adsasdasdasdasd"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::WRONG_EMAIL_CONFIRMATION_TOKEN, res["errors"][0]["code"])
	end

	it "should confirm user" do
		cato = users(:cato)

		res = post_request(
			"/v1/user/#{cato.id}/confirm",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: cato.email_confirmation_token
			}
		)

		assert_response 204

		# Check if the user was updated
		cato = User.find_by(id: cato.id)
		assert_nil(cato.email_confirmation_token)
		assert(cato.confirmed)
	end

	# save_new_email
	it "should not save new email without auth" do
		res = post_request("/v1/user/1/save_new_email")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not save new email without Content-Type json" do
		res = post_request(
			"/v1/user/1/save_new_email",
			{Authorization: "asdsadsdasda"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not save new email without required properties" do
		res = post_request(
			"/v1/user/1/save_new_email",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_CONFIRMATION_TOKEN_MISSING, res["errors"][0]["code"])
	end

	it "should not save new email with properties with wrong types" do
		res = post_request(
			"/v1/user/1/save_new_email",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: false
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_CONFIRMATION_TOKEN_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not save new email with dev that does not exist" do
		res = post_request(
			"/v1/user/1/save_new_email",
			{Authorization: "asdasdasd,asdwfqfwafasf", 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not save new email with invalid auth" do
		res = post_request(
			"/v1/user/1/save_new_email",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasd"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not save new email with another dev than the first one" do
		res = post_request(
			"/v1/user/1/save_new_email",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasasdasdasd"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not save new email of user that does not exist" do
		res = post_request(
			"/v1/user/-123/save_new_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasasdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not save new email of user with empty new_email" do
		res = post_request(
			"/v1/user/#{users(:matt).id}/save_new_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasdasd"
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NEW_EMAIL_OF_USER_IS_EMPTY, res["errors"][0]["code"])
	end

	it "should not save new email with incorrect email confirmation token" do
		cato = users(:cato)

		res = post_request(
			"/v1/user/#{cato.id}/save_new_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasdsda"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::WRONG_EMAIL_CONFIRMATION_TOKEN, res["errors"][0]["code"])
	end

	it "should save new email" do
		cato = users(:cato)
		email_confirmation_token_before = cato.email_confirmation_token
		email_before = cato.email
		new_email_before = cato.new_email

		res = post_request(
			"/v1/user/#{cato.id}/save_new_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: cato.email_confirmation_token
			}
		)

		assert_response 204

		# Check if the user was updated
		cato = User.find_by(id: cato.id)
		assert_not_nil(cato.email_confirmation_token)
		assert_not_equal(email_confirmation_token_before, cato.email_confirmation_token)
		assert_equal(email_before, cato.old_email)
		assert_equal(new_email_before, cato.email)
		assert_nil(cato.new_email)
	end

	# save_new_password
	it "should not save new password without auth" do
		res = post_request("/v1/user/1/save_new_password")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not save new password without Content-Type json" do
		res = post_request(
			"/v1/user/1/save_new_password",
			{Authorization: "asdsaasdasddda"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not save new password without required properties" do
		res = post_request(
			"/v1/user/1/save_new_password",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PASSWORD_CONFIRMATION_TOKEN_MISSING, res["errors"][0]["code"])
	end

	it "should not save new password with properties with wrong types" do
		res = post_request(
			"/v1/user/1/save_new_password",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				password_confirmation_token: []
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PASSWORD_CONFIRMATION_TOKEN_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not save new password with dev that does not exist" do
		res = post_request(
			"/v1/user/1/save_new_password",
			{Authorization: "adasasdasdasd,asdsdasdasfasgafas", 'Content-Type': 'application/json'},
			{
				password_confirmation_token: "asdasdasdasdsda"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not save new password with invalid auth" do
		res = post_request(
			"/v1/user/1/save_new_password",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				password_confirmation_token: "asdasdasdads"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not save new password with another dev than the first one" do
		res = post_request(
			"/v1/user/1/save_new_password",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				password_confirmation_token: "asdasdasdasd"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not save new password of user that does not exist" do
		res = post_request(
			"/v1/user/-123/save_new_password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password_confirmation_token: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not save new password of user with empty new_password" do
		res = post_request(
			"/v1/user/#{users(:matt).id}/save_new_password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password_confirmation_token: "asdasdasdasd"
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NEW_PASSWORD_OF_USER_IS_EMPTY, res["errors"][0]["code"])
	end

	it "should not save new password with incorrect password confirmation token" do
		cato = users(:cato)

		res = post_request(
			"/v1/user/#{cato.id}/save_new_password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password_confirmation_token: "asdasdasdads"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::WRONG_PASSWORD_CONFIRMATION_TOKEN, res["errors"][0]["code"])
	end

	it "should save new password" do
		cato = users(:cato)
		password_digest_before = cato.password_digest
		new_password_before = cato.new_password

		res = post_request(
			"/v1/user/#{cato.id}/save_new_password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password_confirmation_token: cato.password_confirmation_token
			}
		)

		assert_response 204

		# Check if the user was updated
		cato = User.find_by(id: cato.id)
		assert_nil(cato.password_confirmation_token)
		assert_equal(new_password_before, cato.password_digest)
		assert_nil(cato.new_password)

		# The user should be able to authenticate with the new password
		assert(cato.authenticate("654321"))
	end

	# reset_email
	it "should not reset email without auth" do
		res = post_request("/v1/user/1/reset_email")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not reset email without Content-Type json" do
		res = post_request(
			"/v1/user/1/reset_email",
			{Authorization: "asdasdasdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not reset email without required properties" do
		res = post_request(
			"/v1/user/1/reset_email",
			{Authorization: "adsdasasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_CONFIRMATION_TOKEN_MISSING, res["errors"][0]["code"])
	end

	it "should not reset email with properties with wrong types" do
		res = post_request(
			"/v1/user/1/reset_email",
			{Authorization: "asdasasadasdasd", 'Content-Type': 'application/json'},
			{
				email_confirmation_token: true
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_CONFIRMATION_TOKEN_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not reset email with dev that does not exist" do
		res = post_request(
			"/v1/user/1/reset_email",
			{Authorization: "asdasdasd,asdwfqfwafasf", 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not reset email with invalid auth" do
		res = post_request(
			"/v1/user/1/reset_email",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasd"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not reset email with another dev than the first one" do
		res = post_request(
			"/v1/user/1/reset_email",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasasd"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not reset email of user that does not exist" do
		res = post_request(
			"/v1/user/-421/reset_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not reset email of user with empty old_email" do
		res = post_request(
			"/v1/user/#{users(:matt).id}/reset_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasd"
			}
		)

		assert_response 412
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::OLD_EMAIL_OF_USER_IS_EMPTY, res["errors"][0]["code"])
	end

	it "should not reset email with incorrect email confirmation token" do
		cato = users(:cato)

		res = post_request(
			"/v1/user/#{cato.id}/reset_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: "asdasdasdasd"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::WRONG_EMAIL_CONFIRMATION_TOKEN, res["errors"][0]["code"])
	end

	it "should reset email" do
		cato = users(:cato)
		old_email_before = cato.old_email

		res = post_request(
			"/v1/user/#{cato.id}/reset_email",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email_confirmation_token: cato.email_confirmation_token
			}
		)

		assert_response 204

		# Check if the user was updated
		cato = User.find_by(id: cato.id)
		assert_nil(cato.email_confirmation_token)
		assert_nil(cato.old_email)
		assert_equal(cato.email, old_email_before)
	end

	# set_password
	it "should not set password without auth" do
		res = put_request("/v1/user/1/password")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set password without Content-Type json" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set password without required properties" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::PASSWORD_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_CONFIRMATION_TOKEN_MISSING, res["errors"][1]["code"])
	end

	it "should not set password with properties with wrong types" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				password: 1234,
				password_confirmation_token: false
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::PASSWORD_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_CONFIRMATION_TOKEN_WRONG_TYPE, res["errors"][1]["code"])
	end

	it "should not set password with too short properties" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password: "a",
				password_confirmation_token: "adasasdasdasd"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PASSWORD_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not set password with too long properties" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password: "a" * 100,
				password_confirmation_token: "adasasdasdasd"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PASSWORD_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not set password with dev that does not exist" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: "adasasdasdasd,asdsdasdasfasgafas", 'Content-Type': 'application/json'},
			{
				password: "asdasdasdasd",
				password_confirmation_token: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set password with invalid auth" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				password: "asdasdasdasd",
				password_confirmation_token: "asdasdasd"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not set password with another dev than the first one" do
		res = put_request(
			"/v1/user/1/password",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				password: "asdasdasdasd",
				password_confirmation_token: "asdasdasd"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not set password of user that does not exist" do
		res = put_request(
			"/v1/user/-213/password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password: "asdasdasdasd",
				password_confirmation_token: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set password with incorrect password confirmation token" do
		cato = users(:cato)

		res = put_request(
			"/v1/user/#{cato.id}/password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password: "asdasdasd",
				password_confirmation_token: "asdasdsadasd"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::WRONG_PASSWORD_CONFIRMATION_TOKEN, res["errors"][0]["code"])
	end

	it "should set password" do
		cato = users(:cato)
		password = "new password"

		res = put_request(
			"/v1/user/#{cato.id}/password",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				password: password,
				password_confirmation_token: cato.password_confirmation_token
			}
		)

		assert_response 204

		# Check if the user was updated
		cato = User.find_by(id: cato.id)
		assert_nil(cato.password_confirmation_token)
		assert(cato.authenticate(password))
	end
end
