require "test_helper"

describe ApiFunctionsController do
	setup do
		setup
	end

	# set_api_function
	it "should not set api function without auth" do
		res = put_request("/v1/api/1/function")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set api function without Content-Type json" do
		res = put_request(
			"/v1/api/1/function",
			{Authorization: "asdasdasasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set api function with invalid auth" do
		res = put_request(
			"/v1/api/1/function",
			{Authorization: "#{devs(:dav).api_key},jhdfh92h3r9sa", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not set api function without required properties" do
		res = put_request(
			"/v1/api/1/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::COMMANDS_MISSING, res["errors"][1]["code"])
	end

	it "should not set api function with properties with wrong types" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: 12,
				commands: true
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::COMMANDS_WRONG_TYPE, res["errors"][1]["code"])
	end

	it "should not set api function with optional properties with wrong types" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: 12,
				params: 6.3,
				commands: true
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::NAME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PARAMS_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::COMMANDS_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not set api function with too short properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: "a",
				commands: "a"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::COMMANDS_TOO_SHORT, res["errors"][1]["code"])
	end

	it "should not set api function with too long properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: "a" * 250,
				commands: "a" * 65100
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::COMMANDS_TOO_LONG, res["errors"][1]["code"])
	end

	it "should not set api function with too long optional properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: "a" * 250,
				params: "a" * 250,
				commands: "a" * 65100
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::PARAMS_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::COMMANDS_TOO_LONG, res["errors"][2]["code"])
	end

	it "should not set api function for api of the app of another dev" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				name: "TestFunction",
				commands: "(log 'test')"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should create new api function in set api function" do
		api = apis(:pocketlibApi)
		name = "TestFunction"
		commands = "(log 'test')"

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: name,
				commands: commands
			}
		)

		assert_response 200
		
		assert_not_nil(res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(name, res["name"])
		assert_equal("", res["params"])
		assert_equal(commands, res["commands"])

		function = ApiFunction.find_by(id: res["id"])
		assert_not_nil(function)
		assert_equal(function.id, res["id"])
		assert_equal(function.api_id, res["api_id"])
		assert_equal(function.name, res["name"])
		assert_equal(function.params, res["params"])
		assert_equal(function.commands, res["commands"])
	end

	it "should create new api function with optional properties in set api function" do
		api = apis(:pocketlibApi)
		name = "TestFunction"
		params = "bla,test"
		commands = "(log 'test')"

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: name,
				params: params,
				commands: commands
			}
		)

		assert_response 200
		
		assert_not_nil(res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(name, res["name"])
		assert_equal(params, res["params"])
		assert_equal(commands, res["commands"])

		function = ApiFunction.find_by(id: res["id"])
		assert_not_nil(function)
		assert_equal(function.id, res["id"])
		assert_equal(function.api_id, res["api_id"])
		assert_equal(function.name, res["name"])
		assert_equal(function.params, res["params"])
		assert_equal(function.commands, res["commands"])
	end

	it "should update existing api function in set api function" do
		api = apis(:pocketlibApi)
		function = api_functions(:pocketlibApiTestFunction)
		commands = "(log 'test')"

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: function.name,
				commands: commands
			}
		)

		assert_response 200

		assert_not_nil(res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(function.name, res["name"])
		assert_equal(function.params, res["params"])
		assert_equal(commands, res["commands"])
		
		function = ApiFunction.find_by(id: res["id"])
		assert_not_nil(function)
		assert_equal(function.id, res["id"])
		assert_equal(function.api_id, res["api_id"])
		assert_equal(function.name, res["name"])
		assert_equal(function.params, res["params"])
		assert_equal(function.commands, res["commands"])
	end

	it "should update existing api function with optional properties in set api function" do
		api = apis(:pocketlibApi)
		function = api_functions(:pocketlibApiTestFunction)
		params = "test"
		commands = "(log 'test')"

		res = put_request(
			"/v1/api/#{api.id}/function",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				name: function.name,
				params: params,
				commands: commands
			}
		)

		assert_response 200

		assert_not_nil(res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(function.name, res["name"])
		assert_equal(params, res["params"])
		assert_equal(commands, res["commands"])

		function = ApiFunction.find_by(id: res["id"])
		assert_not_nil(function)
		assert_equal(function.id, res["id"])
		assert_equal(function.api_id, res["api_id"])
		assert_equal(function.name, res["name"])
		assert_equal(function.params, res["params"])
		assert_equal(function.commands, res["commands"])
	end
end