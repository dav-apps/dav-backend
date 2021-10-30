require "test_helper"

describe ApiErrorsController do
	setup do
		setup
	end

	# set_api_errors
	it "should not set api errors without auth" do
		res = put_request("/v1/api/1/master/errors")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set api errors without Content-Type json" do
		res = put_request(
			"/v1/api/1/master/errors",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set api errors with invalid auth" do
		res = put_request(
			"/v1/api/1/master/errors",
			{Authorization: "#{devs(:dav).api_key},jhdfh92h3r9sa", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not set api errors without required properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ERRORS_MISSING, res["errors"][0]["code"])
	end

	it "should not set api errors with properties with wrong types" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: "hello world"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ERRORS_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not set api errors with errors with wrong types" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [
					{
						code: 123,
						message: "Hello World"
					},
					{
						code: 14.2,
						message: true
					},
					{
						code: 124,
						message: "Test"
					}
				]
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::CODE_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::MESSAGE_WRONG_TYPE, res["errors"][1]["code"])
	end

	it "should not set api errors with errors with too short properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [
					{
						code: 123,
						message: "Hello World"
					},
					{
						code: 124,
						message: "a"
					}
				]
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::MESSAGE_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not set api errors with too long properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [
					{
						code: 123,
						message: "a" * 260
					},
					{
						code: 124,
						message: "Hello World"
					}
				]
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::MESSAGE_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not set api errors for api that does not exist" do
		res = put_request(
			"/v1/api/-123/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [
					{
						code: 123,
						message: "Hallo Welt"
					},
					{
						code: 124,
						message: "Hello World"
					}
				]
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::API_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set api errors for api of the app of another dev" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				errors: [{code: 123, message: "Testerror"}]
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not set api errors with too short slot name" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/a/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [{code: 123, message: "Testerror"}]
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SLOT_TOO_SHORT, res["errors"][0]["code"])
	end
	
	it "should not set api errors with too long slot name" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/#{'a' * 50}/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [{code: 123, message: "Testerror"}]
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SLOT_TOO_LONG, res["errors"][0]["code"])
	end

	it "should create new api errors in set api errors" do
		api = apis(:pocketlibApi)
		api_slot = api_slots(:pocketlibApiMaster)
		errors_count = api_slot.api_errors.count
		first_error_code = 111
		first_error_message = "First error"
		second_error_code = 222
		second_error_message = "Second error"

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [
					{
						code: first_error_code,
						message: first_error_message
					},
					{
						code: second_error_code,
						message: second_error_message
					}
				]
			}
		)

		assert_response 204
		assert_equal(errors_count + 2, api_slot.api_errors.count)
		
		first_error = ApiError.find_by(api_slot: api_slot, code: first_error_code)
		assert_not_nil(first_error)
		assert_equal(api_slot.id, first_error.api_slot_id)
		assert_equal(first_error_code, first_error.code)
		assert_equal(first_error_message, first_error.message)

		second_error = ApiError.find_by(api_slot: api_slot, code: second_error_code)
		assert_not_nil(second_error)
		assert_equal(api_slot.id, second_error.api_slot_id)
		assert_equal(second_error_code, second_error.code)
		assert_equal(second_error_message, second_error.message)
	end

	it "should create new api errors and create new api slot in set api errors" do
		api = apis(:pocketlibApi)
		api_slot_name = "testslot"
		first_error_code = 111
		first_error_message = "First error"
		second_error_code = 222
		second_error_message = "Second error"

		res = put_request(
			"/v1/api/#{api.id}/#{api_slot_name}/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [
					{
						code: first_error_code,
						message: first_error_message
					},
					{
						code: second_error_code,
						message: second_error_message
					}
				]
			}
		)

		assert_response 204

		api_slot = ApiSlot.find_by(api: api, name: api_slot_name)

		assert_not_nil(api_slot)
		assert_equal(api_slot.name, api_slot_name)
		assert_equal(2, api_slot.api_errors.count)
		
		first_error = ApiError.find_by(api_slot: api_slot, code: first_error_code)
		assert_not_nil(first_error)
		assert_equal(api_slot.id, first_error.api_slot_id)
		assert_equal(first_error_code, first_error.code)
		assert_equal(first_error_message, first_error.message)

		second_error = ApiError.find_by(api_slot: api_slot, code: second_error_code)
		assert_not_nil(second_error)
		assert_equal(api_slot.id, second_error.api_slot_id)
		assert_equal(second_error_code, second_error.code)
		assert_equal(second_error_message, second_error.message)
	end

	it "should update existing api errors in set api errors" do
		api = apis(:pocketlibApi)
		api_slot = api_slots(:pocketlibApiMaster)
		first_error = api_errors(:pocketlibApiFirstError)
		second_error = api_errors(:pocketlibApiSecondError)
		first_error_message = "Updated first error message"
		second_error_message = "Updated second error message"

		res = put_request(
			"/v1/api/#{api.id}/master/errors",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				errors: [
					{
						code: first_error.code,
						message: first_error_message
					},
					{
						code: second_error.code,
						message: second_error_message
					}
				]
			}
		)

		assert_response 204
		assert_equal(2, api_slot.api_errors.count)

		first_error = ApiError.find_by(id: first_error.id)
		assert_not_nil(first_error)
		assert_equal(first_error_message, first_error.message)

		second_error = ApiError.find_by(id: second_error.id)
		assert_not_nil(second_error)
		assert_equal(second_error_message, second_error.message)
	end
end