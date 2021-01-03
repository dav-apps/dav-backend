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
end