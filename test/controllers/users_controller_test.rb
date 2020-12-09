require "test_helper"

describe UsersController do
	setup do
		ENV["DAV_APPS_APP_ID"] = apps(:website).id.to_s
	end

	# signup
	it "should not signup without auth" do
		res = post_request("/v1/signup")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCode::AUTH_MISSING, res["errors"][0]["code"])
	end

	it "should not signup without Content-Type json" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCode::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not signup without required properties" do
		res = post_request(
			"/v1/signup",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCode::EMAIL_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCode::FIRST_NAME_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCode::PASSWORD_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCode::APP_ID_MISSING, res["errors"][3]["code"])
		assert_equal(ErrorCode::API_KEY_MISSING, res["errors"][4]["code"])
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
		assert_equal(ErrorCode::EMAIL_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCode::FIRST_NAME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCode::PASSWORD_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCode::APP_ID_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCode::API_KEY_WRONG_TYPE, res["errors"][4]["code"])
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
		assert_equal(ErrorCode::EMAIL_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCode::FIRST_NAME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCode::PASSWORD_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCode::APP_ID_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCode::API_KEY_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCode::DEVICE_NAME_WRONG_TYPE, res["errors"][5]["code"])
		assert_equal(ErrorCode::DEVICE_TYPE_WRONG_TYPE, res["errors"][6]["code"])
		assert_equal(ErrorCode::DEVICE_OS_WRONG_TYPE, res["errors"][7]["code"])
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
		assert_equal(ErrorCode::FIRST_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCode::PASSWORD_TOO_SHORT, res["errors"][1]["code"])
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
		assert_equal(ErrorCode::FIRST_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCode::PASSWORD_TOO_SHORT, res["errors"][1]["code"])
		assert_equal(ErrorCode::DEVICE_NAME_TOO_SHORT, res["errors"][2]["code"])
		assert_equal(ErrorCode::DEVICE_TYPE_TOO_SHORT, res["errors"][3]["code"])
		assert_equal(ErrorCode::DEVICE_OS_TOO_SHORT, res["errors"][4]["code"])
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
		assert_equal(ErrorCode::FIRST_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCode::PASSWORD_TOO_LONG, res["errors"][1]["code"])
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
		assert_equal(ErrorCode::FIRST_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCode::PASSWORD_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCode::DEVICE_NAME_TOO_LONG, res["errors"][2]["code"])
		assert_equal(ErrorCode::DEVICE_TYPE_TOO_LONG, res["errors"][3]["code"])
		assert_equal(ErrorCode::DEVICE_OS_TOO_LONG, res["errors"][4]["code"])
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

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCode::EMAIL_ALREADY_TAKEN, res["errors"][0]["code"])
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
		assert_equal(ErrorCode::EMAIL_INVALID, res["errors"][0]["code"])
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
		assert_equal(ErrorCode::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
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
		assert_equal(ErrorCode::AUTHENTICATION_FAILED, res["errors"][0]["code"])
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
		assert_equal(ErrorCode::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
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
		assert_equal(ErrorCode::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
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
		assert_equal(ErrorCode::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
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
		assert_equal(ErrorCode::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should signup from website and return the user and jwt" do
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
		
		assert_nil(res["website_jwt"])
	end

	it "should signup from app and return the user, jwt and website jwt" do
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

		# Check the website session
		website_session_id = res["website_jwt"].split('.').last.to_i
		assert_not_equal(0, website_session_id)
		website_session = Session.find_by(id: website_session_id)
		assert_not_nil(website_session)
		assert_equal(website_session_id, website_session.id)
		assert_equal(user, website_session.user)
		assert_equal(apps(:website), website_session.app)
	end

	it "should signup from app of another dev and return the user, jwt and website jwt" do
		email = "test@example.com"
		first_name = "Testuser"
		app = apps(:davApp)

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

		# Check the website session
		website_session_id = res["website_jwt"].split('.').last.to_i
		assert_not_equal(0, website_session_id)
		website_session = Session.find_by(id: website_session_id)
		assert_not_nil(website_session)
		assert_equal(website_session_id, website_session.id)
		assert_equal(user, website_session.user)
		assert_equal(apps(:website), website_session.app)
	end
end

module ErrorCode
	AUTHENTICATION_FAILED = 1102
	ACTION_NOT_ALLOWED = 1103
	CONTENT_TYPE_NOT_SUPPORTED = 1104

	AUTH_MISSING = 2101
	JWT_MISSING = 2102
	EMAIL_MISSING = 2103
	FIRST_NAME_MISSING = 2104
	PASSWORD_MISSING = 2105
	APP_ID_MISSING = 2106
	API_KEY_MISSING = 2107

	EMAIL_WRONG_TYPE = 2201
	FIRST_NAME_WRONG_TYPE = 2202
	PASSWORD_WRONG_TYPE = 2203
	APP_ID_WRONG_TYPE = 2204
	API_KEY_WRONG_TYPE = 2205
	DEVICE_NAME_WRONG_TYPE = 2206
	DEVICE_TYPE_WRONG_TYPE = 2207
	DEVICE_OS_WRONG_TYPE = 2208

	FIRST_NAME_TOO_SHORT = 2301
	PASSWORD_TOO_SHORT = 2302
	DEVICE_NAME_TOO_SHORT = 2303
	DEVICE_TYPE_TOO_SHORT = 2304
	DEVICE_OS_TOO_SHORT = 2305

	FIRST_NAME_TOO_LONG = 2401
	PASSWORD_TOO_LONG = 2402
	DEVICE_NAME_TOO_LONG = 2403
	DEVICE_TYPE_TOO_LONG = 2404
	DEVICE_OS_TOO_LONG = 2405

	EMAIL_INVALID = 2501
	
	EMAIL_ALREADY_TAKEN = 2701

	USER_DOES_NOT_EXIST = 2801
	DEV_DOES_NOT_EXIST = 2802
	APP_DOES_NOT_EXIST = 2803
end
