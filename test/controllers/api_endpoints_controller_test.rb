require "test_helper"

describe ApiEndpointsController do
	setup do
		setup
	end

	# set_api_endpoint
	it "should not set api endpoint without auth" do
		res = put_request("/v1/api/1/endpoint")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set api endpoint without Content-Type json" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: "asdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set api endpoint with invalid auth" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: "#{devs(:dav).api_key},jhdfh92h3r9sa", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not set api endpoint without required properties" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::PATH_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::METHOD_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::COMMANDS_MISSING, res["errors"][2]["code"])
	end

	it "should not set api endpoint with properties with wrong types" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: true,
				method: 12,
				commands: false
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::PATH_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::METHOD_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::COMMANDS_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not set api endpoint with optional properties with wrong types" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: 51.2,
				method: false,
				commands: 63,
				caching: "Hello World"
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::PATH_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::METHOD_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::COMMANDS_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::CACHING_WRONG_TYPE, res["errors"][3]["code"])
	end

	it "should not set api endpoint with too short properties" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: "a",
				method: "get",
				commands: "a"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::PATH_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::COMMANDS_TOO_SHORT, res["errors"][1]["code"])
	end

	it "should not set api endpoint with too long properties" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: "a" * 200,
				method: "get",
				commands: "a" * 65100
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::PATH_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::COMMANDS_TOO_LONG, res["errors"][1]["code"])
	end

	it "should not set api endpoint with invalid method" do
		res = put_request(
			"/v1/api/1/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: "test",
				method: "asdasd",
				commands: "(log 'test')"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::METHOD_INVALID, res["errors"][0]["code"])
	end

	it "should not set api endpoint for api of the app of another dev" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/endpoint",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				path: "test",
				method: "get",
				commands: "(log 'test')"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should create new api endpoint in set api endpoint" do
		api = apis(:pocketlibApi)
		path = "test"
		method = "GET"
		commands = "(log 'test')"

		res = put_request(
			"/v1/api/#{api.id}/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: path,
				method: method,
				commands: commands
			}
		)

		assert_response 200

		assert_not_nil(res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(path, res["path"])
		assert_equal(method, res["method"])
		assert_equal(commands, res["commands"])
		assert(!res["caching"])

		endpoint = ApiEndpoint.find_by(id: res["id"])
		assert_not_nil(endpoint)
		assert_equal(endpoint.id, res["id"])
		assert_equal(endpoint.api_id, res["api_id"])
		assert_equal(endpoint.path, res["path"])
		assert_equal(endpoint.method, res["method"])
		assert_equal(endpoint.commands, res["commands"])
		assert_equal(endpoint.caching, res["caching"])
	end

	it "should create new api endpoint with optional properties in set api endpoint" do
		api = apis(:pocketlibApi)
		path = "test"
		method = "GET"
		commands = "(log 'Bla')"
		caching = true

		res = put_request(
			"/v1/api/#{api.id}/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: path,
				method: method,
				commands: commands,
				caching: caching
			}
		)

		assert_response 200

		assert_not_nil(res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(path, res["path"])
		assert_equal(method, res["method"])
		assert_equal(commands, res["commands"])
		assert_equal(caching, res["caching"])

		endpoint = ApiEndpoint.find_by(id: res["id"])
		assert_not_nil(endpoint)
		assert_equal(endpoint.id, res["id"])
		assert_equal(endpoint.api_id, res["api_id"])
		assert_equal(endpoint.path, res["path"])
		assert_equal(endpoint.method, res["method"])
		assert_equal(endpoint.commands, res["commands"])
		assert_equal(endpoint.caching, res["caching"])
	end

	it "should update existing api endpoint in set api endpoint" do
		api = apis(:pocketlibApi)
		endpoint = api_endpoints(:pocketlibApiPostTest)
		commands = "(log 'test')"

		res = put_request(
			"/v1/api/#{api.id}/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: endpoint.path,
				method: endpoint.method,
				commands: commands
			}
		)

		assert_response 200

		assert_equal(endpoint.id, res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(endpoint.path, res["path"])
		assert_equal(endpoint.method, res["method"])
		assert_equal(commands, res["commands"])
		assert_equal(endpoint.caching, res["caching"])

		endpoint = ApiEndpoint.find_by(id: res["id"])
		assert_not_nil(endpoint)
		assert_equal(endpoint.id, res["id"])
		assert_equal(endpoint.api_id, res["api_id"])
		assert_equal(endpoint.path, res["path"])
		assert_equal(endpoint.method, res["method"])
		assert_equal(endpoint.commands, res["commands"])
		assert_equal(endpoint.caching, res["caching"])
	end

	it "should update existing api endpoint with optional properties in set api endpoint" do
		api = apis(:pocketlibApi)
		endpoint = api_endpoints(:pocketlibApiPostTest)
		commands = "(log 'Hello World')"
		caching = true

		res = put_request(
			"/v1/api/#{api.id}/endpoint",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				path: endpoint.path,
				method: endpoint.method,
				commands: commands,
				caching: caching
			}
		)

		assert_response 200

		assert_equal(endpoint.id, res["id"])
		assert_equal(api.id, res["api_id"])
		assert_equal(endpoint.path, res["path"])
		assert_equal(endpoint.method, res["method"])
		assert_equal(commands, res["commands"])
		assert_equal(caching, res["caching"])

		endpoint = ApiEndpoint.find_by(id: res["id"])
		assert_not_nil(endpoint)
		assert_equal(endpoint.id, res["id"])
		assert_equal(endpoint.api_id, res["api_id"])
		assert_equal(endpoint.path, res["path"])
		assert_equal(endpoint.method, res["method"])
		assert_equal(endpoint.commands, res["commands"])
		assert_equal(endpoint.caching, res["caching"])
	end
end