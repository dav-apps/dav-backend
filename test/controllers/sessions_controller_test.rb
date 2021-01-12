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
		assert_not_nil(res["jwt"])

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
		assert_not_nil(res["jwt"])

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
		assert_not_nil(res["jwt"])

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
		assert_not_nil(res["jwt"])

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
	end

	# create_session_from_jwt
	it "should not create session from jwt without auth" do
		res = post_request("/v1/session/jwt")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create session from jwt without Content-Type jwt" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create session from jwt without required properties" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "asdasasd", 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::APP_ID_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::API_KEY_MISSING, res["errors"][2]["code"])
	end

	it "should not create session from jwt with properties with wrong types" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "asdasdasdas", 'Content-Type': 'application/json'},
			{
				jwt: 124.5,
				app_id: true,
				api_key: 642
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::JWT_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not create session from jwt with optional properties with wrong types" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "asdasdasdas", 'Content-Type': 'application/json'},
			{
				jwt: 124.5,
				app_id: true,
				api_key: 642,
				device_name: false,
				device_type: 963.2,
				device_os: 24
			}
		)

		assert_response 400
		assert_equal(6, res["errors"].length)
		assert_equal(ErrorCodes::JWT_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::API_KEY_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::DEVICE_NAME_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::DEVICE_TYPE_WRONG_TYPE, res["errors"][4]["code"])
		assert_equal(ErrorCodes::DEVICE_OS_WRONG_TYPE, res["errors"][5]["code"])
	end

	it "should not create session from jwt with too short optional properties" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "adasdasdasd", 'Content-Type': 'application/json'},
			{
				jwt: "spjdjfsodfsdfi",
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

	it "should not create session from jwt with too long optional properties" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "adasdasdasd", 'Content-Type': 'application/json'},
			{
				jwt: "spjdjfsodfsdfi",
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

	it "should not create session from jwt with dev that does not exist" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "asdasdasd,asdasdasdasd", 'Content-Type': 'application/json'},
			{
				jwt: "spjdjfsodfsdfi",
				app_id: 1,
				api_key: "sodfsjdgsdnjksfdnklfdfd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session from jwt with invalid auth" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'},
			{
				jwt: "asdasdasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not create session from jwt with another dev than the first one" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				jwt: "asdasdasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create session from jwt with invalid jwt" do
		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				jwt: "asdasdasdasd",
				app_id: 1,
				api_key: "asdassda"
			}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not create session from jwt that is not for the website" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				jwt: jwt,
				app_id: 1,
				api_key: "aasdasdasdad"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create session from jwt for app that does not exist" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				jwt: jwt,
				app_id: -1233,
				api_key: "sadadasdasdasd"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session from jwt with api key for dev that does not exist" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				jwt: jwt,
				app_id: apps(:cards).id,
				api_key: "sadasdassda"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create session from jwt for app that does not belong to the dev" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				jwt: jwt,
				app_id: apps(:cards).id,
				api_key: devs(:dav).api_key
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should create session from jwt" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))
		dev = devs(:sherlock)
		user = users(:matt)
		app = apps(:cards)

		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(dev), 'Content-Type': 'application/json'},
			{
				jwt: jwt,
				app_id: app.id,
				api_key: dev.api_key
			}
		)

		assert_response 201
		assert_not_nil(res["jwt"])

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
	end

	it "should create session from jwt with device info" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))
		dev = devs(:sherlock)
		user = users(:matt)
		app = apps(:cards)
		device_name = "Surface Phone"
		device_type = "Dual-Screen"
		device_os = "Andromeda"

		res = post_request(
			"/v1/session/jwt",
			{Authorization: generate_auth(dev), 'Content-Type': 'application/json'},
			{
				jwt: jwt,
				app_id: app.id,
				api_key: dev.api_key,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			}
		)

		assert_response 201
		assert_not_nil(res["jwt"])

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
	end

	# delete_session
	it "should not delete session without jwt" do
		res = delete_request("/v1/session")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not delete session with invalid jwt" do
		res = delete_request(
			"/v1/session",
			{Authorization: "asdas.asdasd.asdas"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not delete session that does not exist" do
		jwt = generate_jwt(sessions(:mattTestAppSession))
		sessions(:mattTestAppSession).destroy!
		
		res = delete_request(
			"/v1/session",
			{Authorization: jwt}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should delete session" do
		jwt = generate_jwt(sessions(:mattTestAppSession))

		delete_request(
			"/v1/session",
			{Authorization: jwt}
		)

		assert_response 204
	end
end