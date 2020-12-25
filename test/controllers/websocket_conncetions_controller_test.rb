require "test_helper"

describe WebsocketConnectionsController do
	setup do
		setup
	end

	# create_websocket_connection
	it "should not create websocket connection without jwt" do
		res = post_request("/v1/websocket_connection")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not create websocket connection with invalid jwt" do
		res = post_request(
			"/v1/websocket_connection",
			{Authorization: "asdasdasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should create a websocket connection" do
		session = sessions(:mattCardsSession)
		jwt = generate_jwt(session)

		res = post_request(
			"/v1/websocket_connection",
			{Authorization: jwt}
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