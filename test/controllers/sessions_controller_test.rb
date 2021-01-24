require "test_helper"

describe SessionsController do
	setup do
		setup
	end

	# create_session
	it "should not create session without auth" do
		res = post_request("/v1/session")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create session without Content-Type json" do
		res = post_request(
			"/v1/session",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create session without required properties" do
		res = post_request(
			"/v1/session",
			{Authorization: "asdasd", 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::APP_ID_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCodes::API_KEY_MISSING, res["errors"][3]["code"])
	end

	it "should not create session with properties with wrong types" do
		res = post_request(
			"/v1/session",
			{Authorization: "asdasda", 'Content-Type': 'application/json'},
			{
				email: true,
				password: 12345,
				app_id: "test",
				api_key: 12.345
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][3]["code"])
	end

	it "should not create session with optional properties with wrong types" do
		res = post_request(
			"/v1/session",
			{Authorization: "asdasda", 'Content-Type': 'application/json'},
			{
				email: true,
				password: 12345,
				app_id: "test",
				api_key: 12.345,
				device_name: false,
				device_type: 123,
				device_os: 123
			}
		)

		assert_response 400
		assert_equal(7, res["errors"].length)
		assert_equal(ErrorCodes::EMAIL_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PASSWORD_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::DEVICE_NAME_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_WRONG_TYPE, res["errors"][5]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_WRONG_TYPE, res["errors"][6]["code"])
	end

	it "should not create session with too short optional properties" do
		res = post_request(
			"/v1/session",
			{Authorization: "asdasda", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: 1,
				api_key: "asdassda",
				device_name: "a",
				device_type: "a",
				device_os: "a"
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::DEVICE_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_TOO_SHORT, res["errors"][1]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_TOO_SHORT, res["errors"][2]["code"])
	end

	it "should not create session with too long optional properties" do
		res = post_request(
			"/v1/session",
			{Authorization: "asdasda", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: 1,
				api_key: "asdassda",
				device_name: "a" * 50,
				device_type: "a" * 50,
				device_os: "a" * 50
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::DEVICE_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_TOO_LONG, res["errors"][2]["code"])
	end

	it "should not create session with dev that does not exist" do
		res = post_request(
			"/v1/session",
			{Authorization: "asdasda,asdasdasd", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session with invalid auth" do
		res = post_request(
			"/v1/session",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not create session with another dev than the first one" do
		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create session for app that does not exist" do
		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: -412,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session with api key for dev that does not exist" do
		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: apps(:cards).id,
				api_key: "asdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session for app that does not belong to the dev" do
		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: apps(:cards).id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create session for user that does not exist" do
		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: "test@example.com",
				password: "saasdasd",
				app_id: apps(:testApp).id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::USER_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session with wrong password" do
		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: users(:matt).email,
				password: "asdasdaasd",
				app_id: apps(:testApp).id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::WRONG_PASSWORD, res["errors"][0]["code"])
	end

	it "should create session" do
		user = users(:matt)
		app = apps(:cards)

		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: user.email,
				password: Constants::MATT_PASSWORD,
				app_id: app.id,
				api_key: devs(:sherlock).api_key
			}
		)

		assert_response 201
		assert_not_nil(res["access_token"])

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)
	end

	it "should create session with device info" do
		user = users(:matt)
		app = apps(:cards)
		device_name = "Surface Phone"
		device_type = "Dual-Screen"
		device_os = "Andromeda"

		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: user.email,
				password: Constants::MATT_PASSWORD,
				app_id: app.id,
				api_key: devs(:sherlock).api_key,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			}
		)

		assert_response 201
		assert_not_nil(res["access_token"])

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)
	end

	it "should create session for the app of another dev" do
		user = users(:matt)
		app = apps(:testApp)

		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: user.email,
				password: Constants::MATT_PASSWORD,
				app_id: app.id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 201
		assert_not_nil(res["access_token"])

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)
	end

	it "should create session with device info for the app of another dev" do
		user = users(:matt)
		app = apps(:testApp)
		device_name = "Surface Phone"
		device_type = "Dual-Screen"
		device_os = "Andromeda"

		res = post_request(
			"/v1/session",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				email: user.email,
				password: Constants::MATT_PASSWORD,
				app_id: app.id,
				api_key: devs(:dav).api_key,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			}
		)

		assert_response 201
		assert_not_nil(res["access_token"])

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)
	end

	# create_session_from_access_token
	it "should not create session from access token without auth" do
		res = post_request("/v1/session/access_token")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create session from access token without Content-Type json" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create session from access token without required properties" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "asdasasd", 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::ACCESS_TOKEN_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::APP_ID_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::API_KEY_MISSING, res["errors"][2]["code"])
	end

	it "should not create session from access token with properties with wrong types" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "asdasdasdas", 'Content-Type': 'application/json'},
			{
				access_token: 124.5,
				app_id: true,
				api_key: 642
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::ACCESS_TOKEN_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not create session from access token with optional properties with wrong types" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "asdasdasdas", 'Content-Type': 'application/json'},
			{
				access_token: 124.5,
				app_id: true,
				api_key: 642,
				device_name: false,
				device_type: 963.2,
				device_os: 24
			}
		)

		assert_response 400
		assert_equal(6, res["errors"].length)
		assert_equal(ErrorCodes::ACCESS_TOKEN_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::DEVICE_NAME_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_WRONG_TYPE, res["errors"][5]["code"])
	end

	it "should not create session from access token with too short optional properties" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "adasdasdasd", 'Content-Type': 'application/json'},
			{
				access_token: "spjdjfsodfsdfi",
				app_id: 1,
				api_key: "sodfsjdgsdnjksfdnklfdfd",
				device_name: "a",
				device_type: "a",
				device_os: "a"
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::DEVICE_NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_TOO_SHORT, res["errors"][1]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_TOO_SHORT, res["errors"][2]["code"])
	end

	it "should not create session from access token with too long optional properties" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "adasdasdasd", 'Content-Type': 'application/json'},
			{
				access_token: "spjdjfsodfsdfi",
				app_id: 1,
				api_key: "sodfsjdgsdnjksfdnklfdfd",
				device_name: "a" * 50,
				device_type: "a" * 50,
				device_os: "a" * 50
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::DEVICE_NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_TOO_LONG, res["errors"][2]["code"])
	end

	it "should not create session from access token with dev that does not exist" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "asdasdasd,asdasdasdasd", 'Content-Type': 'application/json'},
			{
				access_token: "spjdjfsodfsdfi",
				app_id: 1,
				api_key: "sodfsjdgsdnjksfdnklfdfd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session from access token with invalid auth" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				access_token: "asdasdasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not create session from access token with another dev than the first one" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				access_token: "asdasdasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create session from access token of session that does not exist" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				access_token: "asdasdasdasd",
				app_id: 1,
				api_key: "asdasdsadsad"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session from access token with old access token" do
		access_token = sessions(:mattWebsiteSession).old_token

		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				access_token: access_token,
				app_id: 1,
				api_key: "asdasdsad"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CANNOT_USE_OLD_ACCESS_TOKEN, res["errors"][0]["code"])
	end

	it "should not create session from access token of session that must be renewed" do
		session = sessions(:mattWebsiteSession)
		session.updated_at = Time.now - 3.days
		session.save

		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				access_token: session.token,
				app_id: 1,
				api_key: "asdasdasdasd"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACCESS_TOKEN_MUST_BE_RENEWED, res["errors"][0]["code"])
	end

	it "should not create session from access token of session that is not for the website" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				access_token: sessions(:mattCardsSession).token,
				app_id: 1,
				api_key: "aasdasdasdad"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create session from access token for app that does not exist" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				access_token: sessions(:mattWebsiteSession).token,
				app_id: -1233,
				api_key: "sadadasdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session from access token with api key for dev that does not exist" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				access_token: sessions(:mattWebsiteSession).token,
				app_id: apps(:cards).id,
				api_key: "sadasdassda"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session from access token for app that does not belong to the dev" do
		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				access_token: sessions(:mattWebsiteSession).token,
				app_id: apps(:cards).id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should create session from access token" do
		dev = devs(:sherlock)
		user = users(:matt)
		app = apps(:cards)

		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(dev), 'Content-Type': 'application/json'},
			{
				access_token: sessions(:mattWebsiteSession).token,
				app_id: app.id,
				api_key: dev.api_key
			}
		)

		assert_response 201
		assert_not_nil(res["access_token"])

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(res["access_token"], session.token)
		assert_nil(session.device_name)
		assert_nil(session.device_type)
		assert_nil(session.device_os)
	end

	it "should create session from access token with device info" do
		dev = devs(:sherlock)
		user = users(:matt)
		app = apps(:cards)
		device_name = "Surface Phone"
		device_type = "Dual-Screen"
		device_os = "Andromeda"

		res = post_request(
			"/v1/session/access_token",
			{Authorization: generate_auth(dev), 'Content-Type': 'application/json'},
			{
				access_token: sessions(:mattWebsiteSession).token,
				app_id: app.id,
				api_key: dev.api_key,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			}
		)

		assert_response 201
		assert_not_nil(res["access_token"])

		# Check the session
		session = Session.find_by(token: res["access_token"])
		assert_not_nil(session)
		assert_equal(user, session.user)
		assert_equal(app, session.app)
		assert_equal(res["access_token"], session.token)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)
	end

	# renew_session
	it "should not renew session without access token" do
		res = put_request("/v1/session/renew")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not renew session with access token of session that does not exist" do
		res = put_request(
			"/v1/session/renew",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not renew session with old access token" do
		session = sessions(:mattWebsiteSession)

		res = put_request(
			"/v1/session/renew",
			{Authorization: session.old_token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CANNOT_USE_OLD_ACCESS_TOKEN, res["errors"][0]["code"])

		# Check if the session was deleted
		session = Session.find_by(id: session.id)
		assert_nil(session)
	end

	it "should renew session" do
		session = sessions(:mattWebsiteSession)
		session.updated_at = Time.now - 3.days
		session.save
		old_token = session.token

		res = put_request(
			"/v1/session/renew",
			{Authorization: session.token}
		)

		assert_response 200
		assert_not_nil(res["access_token"])

		session = Session.find_by(id: session.id)
		assert_not_nil(session)
		assert_equal(res["access_token"], session.token)
		assert_equal(old_token, session.old_token)
	end

	it "should renew session that does not need to be renewed" do
		session = sessions(:mattWebsiteSession)
		old_token = session.token

		res = put_request(
			"/v1/session/renew",
			{Authorization: session.token}
		)

		assert_response 200
		assert_not_nil(res["access_token"])

		session = Session.find_by(id: session.id)
		assert_not_nil(session)
		assert_equal(res["access_token"], session.token)
		assert_equal(old_token, session.old_token)
	end

	# delete_session
	it "should not delete session without access token" do
		res = delete_request("/v1/session")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not delete session that does not exist" do
		res = delete_request(
			"/v1/session",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should delete session" do
		session = sessions(:mattTestAppSession)

		delete_request(
			"/v1/session",
			{Authorization: session.token}
		)

		assert_response 204

		# Check if the session was deleted
		session = Session.find_by(id: session.id)
		assert_nil(session)
	end
end