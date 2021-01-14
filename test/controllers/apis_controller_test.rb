require "test_helper"

describe ApisController do
	setup do
		setup
	end

	# api_call
	it "should not do api call for api that does not exist" do
		res = get_request(
			"/v1/api/-123/call/test"
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::API_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not do api call for api endpoint that does not exist" do
		res = get_request(
			"/v1/api/#{apis(:pocketlibApi).id}/call/asdasdasd"
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::API_ENDPOINT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should do api call with get method and url params" do
		endpoint = api_endpoints(:pocketlibApiGetTest)
		text = "Hello World"
		id = 4

		res = get_request(
			"/v1/api/#{apis(:pocketlibApi).id}/call/test/#{id}?text=#{text}"
		)

		assert_response 200
		
		assert_equal(text, res["get_text"])
		assert_equal(id, res["id"])
	end

	it "should do api call with post method and url params" do
		endpoint = api_endpoints(:pocketlibApiPostTest)
		text = "Hallo Welt"
		id = 674

		res = post_request(
			"/v1/api/#{apis(:pocketlibApi).id}/call/test/#{id}?text=#{text}"
		)

		assert_response 200
		
		assert_equal(text, res["post_text"])
		assert_equal(id, res["id"])
	end

	it "should do api call with put method and url params" do
		endpoint = api_endpoints(:pocketlibApiPutTest)
		text = "Test"
		id = 145

		res = put_request(
			"/v1/api/#{apis(:pocketlibApi).id}/call/test/#{id}?text=#{text}"
		)

		assert_response 200
		
		assert_equal(text, res["put_text"])
		assert_equal(id, res["id"])
	end

	it "should do api call with delete method and url params" do
		endpoint = api_endpoints(:pocketlibApiDeleteTest)
		text = "Test"
		id = 50

		res = delete_request(
			"/v1/api/#{apis(:pocketlibApi).id}/call/test/#{id}?text=#{text}"
		)

		assert_response 200
		
		assert_equal(text, res["delete_text"])
		assert_equal(id, res["id"])
	end

	# create_api
	it "should not create api without jwt" do
		res = post_request("/v1/api")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create api without Content-Type json" do
		res = post_request(
			"/v1/api",
			{Authorization: "adasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create api with invalid jwt" do
		res = post_request(
			"/v1/api",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not create api without required properties" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = post_request(
			"/v1/api",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::APP_ID_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::NAME_MISSING, res["errors"][1]["code"])
	end

	it "should not create api with properties with wrong types" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = post_request(
			"/v1/api",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: "4",
				name: 15
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::NAME_WRONG_TYPE, res["errors"][1]["code"])
	end

	it "should not create api for app that does not exist" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = post_request(
			"/v1/api",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: -413,
				name: "TestApi"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create api with jwt for app that is not the website" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = post_request(
			"/v1/api",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: apps(:cards).id,
				name: "TestApi"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create api for app of another dev" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/api",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: apps(:cards).id,
				name: "TestApi"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should create api" do
		jwt = generate_jwt(sessions(:davWebsiteSession))
		app = apps(:testApp)
		name = "TestApi"
		
		res = post_request(
			"/v1/api",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: app.id,
				name: "TestApi"
			}
		)

		assert_response 201

		assert_not_nil(res["id"])
		assert_equal(app.id, res["app_id"])
		assert_equal(name, res["name"])
		assert_equal(0, res["endpoints"].length)
		assert_equal(0, res["functions"].length)
		assert_equal(0, res["errors"].length)

		api = Api.find_by(id: res["id"])
		assert_not_nil(api)
		assert_equal(api.id, res["id"])
		assert_equal(api.app_id, res["app_id"])
		assert_equal(api.name, res["name"])
		assert_equal(0, api.api_endpoints.length)
		assert_equal(0, api.api_functions.length)
		assert_equal(0, api.api_errors.length)
	end

	# get_api
	it "should not get api without jwt" do
		res = get_request("/v1/api/1")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get api with invalid jwt" do
		res = get_request(
			"/v1/api/1",
			{Authorization: "adsasdasasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not get api from another app than the website" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = get_request(
			"/v1/api/1",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get api that does not exist" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = get_request(
			"/v1/api/-123",
			{Authorization: jwt}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::API_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get api that belongs to the app of another dev" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))
		api = apis(:pocketlibApi)

		res = get_request(
			"/v1/api/#{apis(:pocketlibApi).id}",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get api" do
		jwt = generate_jwt(sessions(:davWebsiteSession))
		api = apis(:pocketlibApi)

		res = get_request(
			"/v1/api/#{api.id}",
			{Authorization: jwt}
		)

		assert_response 200

		assert_equal(api.id, res["id"])
		assert_equal(api.app_id, res["app_id"])
		assert_equal(api.name, res["name"])

		assert_equal(api.api_endpoints.length, res["endpoints"].length)
		assert_equal(api.api_functions.length, res["functions"].length)
		assert_equal(api.api_errors.length, res["errors"].length)
		
		i = 0
		api.api_endpoints.each do |endpoint|
			assert_equal(endpoint.id, res["endpoints"][i]["id"])
			assert_equal(endpoint.path, res["endpoints"][i]["path"])
			assert_equal(endpoint.method, res["endpoints"][i]["method"])
			assert_equal(endpoint.caching, res["endpoints"][i]["caching"])
			i += 1
		end

		i = 0
		api.api_functions.each do |function|
			assert_equal(function.id, res["functions"][i]["id"])
			assert_equal(function.name, res["functions"][i]["name"])
			assert_equal(function.params, res["functions"][i]["params"])
			i += 1
		end
		
		i = 0
		api.api_errors.each do |error|
			assert_equal(error.id, res["errors"][i]["id"])
			assert_equal(error.code, res["errors"][i]["code"])
			assert_equal(error.message, res["errors"][i]["message"])
			i += 1
		end
	end
end