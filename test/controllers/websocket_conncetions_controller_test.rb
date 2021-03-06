require "test_helper"

describe WebsocketConnectionsController do
	setup do
		setup
	end

	# create_websocket_connection
	it "should not create websocket connection without access token" do
		res = post_request("/v1/websocket_connection")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create websocket connection with access token of session that does not exist" do
		res = post_request(
			"/v1/websocket_connection",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should create websocket connection" do
		session = sessions(:mattCardsSession)

		res = post_request(
			"/v1/websocket_connection",
			{Authorization: session.token}
		)

		assert_response 201
		assert_not_nil(res["token"])

		connection = WebsocketConnection.find_by(token: res["token"])
		assert_not_nil(connection)
		assert_equal(session.user, connection.user)
		assert_equal(session.app, connection.app)
		assert_equal(connection.token, res["token"])
	end
end