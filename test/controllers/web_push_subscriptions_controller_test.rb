require "test_helper"

describe WebPushSubscriptionsController do
	setup do
		setup
	end

	# create_web_push_subscription
	it "should not create web push subscription without jwt" do
		res = post_request("/v1/web_push_subscription")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not create web push subscription without Content-Type json" do
		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: "adsasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create web push subscription with invalid jwt" do
		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: "asdasdsadsda", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not create web push subscription without required properties" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::ENDPOINT_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::P256DH_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::AUTH_MISSING, res["errors"][2]["code"])
	end

	it "should not create web push subscription with properties with wrong types" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				endpoint: 123,
				p256dh: true,
				auth: 12.5
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::ENDPOINT_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::P256DH_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::AUTH_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not create web push subscription with optional properties with wrong types" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				endpoint: 123,
				p256dh: true,
				auth: 12.5,
				uuid: false
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::UUID_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::ENDPOINT_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::P256DH_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::AUTH_WRONG_TYPE, res["errors"][3]["code"])
	end

	it "should not create web push subscription with too short properties" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				endpoint: "",
				p256dh: "",
				auth: ""
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::ENDPOINT_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::P256DH_TOO_SHORT, res["errors"][1]["code"])
		assert_equal(ErrorCodes::AUTH_TOO_SHORT, res["errors"][2]["code"])
	end

	it "should not create web push subscription with too long properties" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				endpoint: "a" * 300,
				p256dh: "a" * 300,
				auth: "a" * 300
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::ENDPOINT_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::P256DH_TOO_LONG, res["errors"][1]["code"])
		assert_equal(ErrorCodes::AUTH_TOO_LONG, res["errors"][2]["code"])
	end

	it "should not create web push subscription with uuid that is already in use" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		subscription = web_push_subscriptions(:mattCardsWebPushSubscription)

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				uuid: subscription.uuid,
				endpoint: "https://notify.windows.com/asdasdasd",
				p256dh: "asasdasdasdads",
				auth: "asdasdad2e20rhwefwe"
			}
		)

		assert_response 409
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::UUID_ALREADY_TAKEN, res["errors"][0]["code"])
	end

	it "should create web push subscription" do
		session = sessions(:mattCardsSession)
		jwt = generate_jwt(session)
		endpoint = "https://fcm.google.com/..."
		p256dh = "asdasdasdasd"
		auth = "oshdfuhw9ehuosfd"

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				endpoint: endpoint,
				p256dh: p256dh,
				auth: auth
			}
		)

		assert_response 201
		
		assert_not_nil(res["id"])
		assert_equal(session.id, res["session_id"])
		assert_not_nil(res["uuid"])
		assert_equal(endpoint, res["endpoint"])
		assert_equal(p256dh, res["p256dh"])
		assert_equal(auth, res["auth"])

		subscription = WebPushSubscription.find_by(id: res["id"])
		assert_not_nil(subscription)
		assert_equal(subscription.id, res["id"])
		assert_equal(subscription.session_id, res["session_id"])
		assert_equal(subscription.uuid, res["uuid"])
		assert_equal(subscription.endpoint, res["endpoint"])
		assert_equal(subscription.p256dh, res["p256dh"])
		assert_equal(subscription.auth, res["auth"])
	end

	it "should create web push subscription with uuid" do
		session = sessions(:mattCardsSession)
		jwt = generate_jwt(session)
		uuid = SecureRandom.uuid
		endpoint = "https://fcm.google.com/..."
		p256dh = "asdasdasdasd"
		auth = "oshdfuhw9ehuosfd"

		res = post_request(
			"/v1/web_push_subscription",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				uuid: uuid,
				endpoint: endpoint,
				p256dh: p256dh,
				auth: auth
			}
		)

		assert_response 201
		
		assert_not_nil(res["id"])
		assert_equal(session.id, res["session_id"])
		assert_equal(uuid, res["uuid"])
		assert_equal(endpoint, res["endpoint"])
		assert_equal(p256dh, res["p256dh"])
		assert_equal(auth, res["auth"])

		subscription = WebPushSubscription.find_by(id: res["id"])
		assert_not_nil(subscription)
		assert_equal(subscription.id, res["id"])
		assert_equal(subscription.session_id, res["session_id"])
		assert_equal(subscription.uuid, res["uuid"])
		assert_equal(subscription.endpoint, res["endpoint"])
		assert_equal(subscription.p256dh, res["p256dh"])
		assert_equal(subscription.auth, res["auth"])
	end
end