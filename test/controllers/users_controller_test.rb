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
		assert_equal(ErrorCodes::AUTH_MISSING, res["errors"][0]["code"])
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
		assert_equal(0, res["user"]["plan"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])
		
		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.plan)
		assert_equal(0, user.used_storage)

		# Check the session
		session_id = res["jwt"].split('.').last.to_i
		assert_not_equal(0, session_id)
		session = Session.find_by(id: session_id)
		assert_not_nil(session)
		assert_equal(session_id, session.id)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)
		
		assert_nil(res["website_jwt"])
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
		assert_equal(0, res["user"]["plan"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.plan)
		assert_equal(0, user.used_storage)

		# Check the session
		session_id = res["jwt"].split('.').last.to_i
		assert_not_equal(0, session_id)
		session = Session.find_by(id: session_id)
		assert_not_nil(session)
		assert_equal(session_id, session.id)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)

		# Check the website session
		website_session_id = res["website_jwt"].split('.').last.to_i
		assert_not_equal(0, website_session_id)
		website_session = Session.find_by(id: website_session_id)
		assert_not_nil(website_session)
		assert_equal(website_session_id, website_session.id)
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
		assert_equal(0, res["user"]["plan"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.plan)
		assert_equal(0, user.used_storage)

		# Check the session
		session_id = res["jwt"].split('.').last.to_i
		assert_not_equal(0, session_id)
		session = Session.find_by(id: session_id)
		assert_not_nil(session)
		assert_equal(session_id, session.id)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)

		# Check the website session
		website_session_id = res["website_jwt"].split('.').last.to_i
		assert_not_equal(0, website_session_id)
		website_session = Session.find_by(id: website_session_id)
		assert_not_nil(website_session)
		assert_equal(website_session_id, website_session.id)
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
		assert_equal(0, res["user"]["plan"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.plan)
		assert_equal(0, user.used_storage)

		# Check the session
		session_id = res["jwt"].split('.').last.to_i
		assert_not_equal(0, session_id)
		session = Session.find_by(id: session_id)
		assert_not_nil(session)
		assert_equal(session_id, session.id)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)
		
		assert_nil(res["website_jwt"])
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
		assert_equal(0, res["user"]["plan"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.plan)
		assert_equal(0, user.used_storage)

		# Check the session
		session_id = res["jwt"].split('.').last.to_i
		assert_not_equal(0, session_id)
		session = Session.find_by(id: session_id)
		assert_not_nil(session)
		assert_equal(session_id, session.id)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)

		# Check the website session
		website_session_id = res["website_jwt"].split('.').last.to_i
		assert_not_equal(0, website_session_id)
		website_session = Session.find_by(id: website_session_id)
		assert_not_nil(website_session)
		assert_equal(website_session_id, website_session.id)
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
		assert_equal(0, res["user"]["plan"])
		assert_equal(UtilsService.get_total_storage(res["user"]["plan"], res["user"]["confirmed"]), res["user"]["total_storage"])
		assert_equal(0, res["user"]["used_storage"])

		# Check the user
		user = User.find_by(id: res["user"]["id"])
		assert_not_nil(user)
		assert_equal(res["user"]["id"], user.id)
		assert_equal(res["user"]["email"], user.email)
		assert_equal(res["user"]["first_name"], user.first_name)
		assert(!user.confirmed)
		assert_equal(0, user.plan)
		assert_equal(0, user.used_storage)

		# Check the session
		session_id = res["jwt"].split('.').last.to_i
		assert_not_equal(0, session_id)
		session = Session.find_by(id: session_id)
		assert_not_nil(session)
		assert_equal(session_id, session.id)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)

		# Check the website session
		website_session_id = res["website_jwt"].split('.').last.to_i
		assert_not_equal(0, website_session_id)
		website_session = Session.find_by(id: website_session_id)
		assert_not_nil(website_session)
		assert_equal(website_session_id, website_session.id)
		assert_equal(user, website_session.user)
		assert_equal(apps(:website), website_session.app)
		assert_equal(device_name, website_session.device_name)
		assert_equal(device_type, website_session.device_type)
		assert_equal(device_os, website_session.device_os)
	end

	# get_user
	it "should not get user without jwt" do
		res = get_request("/v1/user")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not get user with invalid jwt" do
		res = get_request(
			"/v1/user",
			{Authorization: "asdasdasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should return user" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = get_request(
			"/v1/user",
			{Authorization: jwt}
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
	end

	it "should return user with additional information with website session" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = get_request(
			"/v1/user",
			{Authorization: jwt}
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
		assert_nil(cards.google_play_link, res["apps"][0]["google_play_link"])
		assert_nil(cards.microsoft_store_link, res["apps"][0]["microsoft_store_link"])
	end
end
