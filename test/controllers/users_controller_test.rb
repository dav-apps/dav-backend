require "test_helper"

describe UsersController do
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
end

module ErrorCode
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
end
