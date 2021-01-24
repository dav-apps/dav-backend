require "test_helper"

describe NotificationsController do
	setup do
		setup
	end

	# create_notification
	it "should not create notification without access token" do
		res = post_request("/v1/notification")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create notification without Content-Type json" do
		res = post_request(
			"/v1/notification",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create notification with access token for session that does not exist" do
		res = post_request(
			"/v1/notification",
			{Authorization: "asdasdsad", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create notification without required properties" do
		res = post_request(
			"/v1/notification",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::TIME_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::INTERVAL_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::TITLE_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCodes::BODY_MISSING, res["errors"][3]["code"])
	end

	it "should not create notification with properties with wrong types" do
		res = post_request(
			"/v1/notification",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				time: "hello",
				interval: 12.5,
				title: true,
				body: 64
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::TIME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::INTERVAL_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::TITLE_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::BODY_WRONG_TYPE, res["errors"][3]["code"])
	end

	it "should not create notification with optional properties with wrong types" do
		res = post_request(
			"/v1/notification",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				uuid: false,
				time: "hello",
				interval: 12.5,
				title: true,
				body: 64
			}
		)

		assert_response 400
		assert_equal(5, res["errors"].length)
		assert_equal(ErrorCodes::UUID_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::TIME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::INTERVAL_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::TITLE_WRONG_TYPE, res["errors"][3]["code"])
		assert_equal(ErrorCodes::BODY_WRONG_TYPE, res["errors"][4]["code"])
	end

	it "should not create notification with too short properties" do
		res = post_request(
			"/v1/notification",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				time: Time.now.to_i,
				interval: 200000,
				title: "a",
				body: "a"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::TITLE_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::BODY_TOO_SHORT, res["errors"][1]["code"])
	end

	it "should not create notification with too long properties" do
		res = post_request(
			"/v1/notification",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				time: Time.now.to_i,
				interval: 200000,
				title: "a" * 200,
				body: "a" * 200
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::TITLE_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::BODY_TOO_LONG, res["errors"][1]["code"])
	end

	it "should not create notification with uuid that is already in use" do
		notification = notifications(:mattCardsFirstNotification)

		res = post_request(
			"/v1/notification",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				uuid: notification.uuid,
				time: Time.now.to_i,
				interval: 14000,
				title: "Hello World",
				body: "Test notification"
			}
		)

		assert_response 409
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::UUID_ALREADY_TAKEN, res["errors"][0]["code"])
	end

	it "should create notification" do
		session = sessions(:mattCardsSession)
		time = (Time.now - 1.month).to_i
		interval = 1.day.to_i
		title = "Hello World"
		body = "This is a test notification"

		res = post_request(
			"/v1/notification",
			{Authorization: session.token, 'Content-Type': 'application/json'},
			{
				time: time,
				interval: interval,
				title: title,
				body: body
			}
		)

		assert_response 201
		
		assert_not_nil(res["id"])
		assert_equal(session.user_id, res["user_id"])
		assert_equal(session.app_id, res["app_id"])
		assert_not_nil(res["uuid"])
		assert_equal(time, res["time"])
		assert_equal(interval, res["interval"])
		assert_equal(title, res["title"])
		assert_equal(body, res["body"])

		notification = Notification.find_by(id: res["id"])
		assert_not_nil(notification)
		assert_equal(notification.id, res["id"])
		assert_equal(notification.user_id, res["user_id"])
		assert_equal(notification.app_id, res["app_id"])
		assert_equal(notification.uuid, res["uuid"])
		assert_equal(notification.time.to_i, res["time"])
		assert_equal(notification.interval, res["interval"])
		assert_equal(notification.title, res["title"])
		assert_equal(notification.body, res["body"])
	end

	it "should create notification with uuid" do
		session = sessions(:mattCardsSession)
		uuid = SecureRandom.uuid
		time = (Time.now - 1.month).to_i
		interval = 1.day.to_i
		title = "Hello World"
		body = "This is a test notification"

		res = post_request(
			"/v1/notification",
			{Authorization: session.token, 'Content-Type': 'application/json'},
			{
				uuid: uuid,
				time: time,
				interval: interval,
				title: title,
				body: body
			}
		)

		assert_response 201
		
		assert_not_nil(res["id"])
		assert_equal(session.user_id, res["user_id"])
		assert_equal(session.app_id, res["app_id"])
		assert_equal(uuid, res["uuid"])
		assert_equal(time, res["time"])
		assert_equal(interval, res["interval"])
		assert_equal(title, res["title"])
		assert_equal(body, res["body"])

		notification = Notification.find_by(id: res["id"])
		assert_not_nil(notification)
		assert_equal(notification.id, res["id"])
		assert_equal(notification.user_id, res["user_id"])
		assert_equal(notification.app_id, res["app_id"])
		assert_equal(notification.uuid, res["uuid"])
		assert_equal(notification.time.to_i, res["time"])
		assert_equal(notification.interval, res["interval"])
		assert_equal(notification.title, res["title"])
		assert_equal(notification.body, res["body"])
	end

	# get_notifications
	it "should not get notifications without access token" do
		res = get_request("/v1/notifications")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get notifications with access token for session that does not exist" do
		res = get_request(
			"/v1/notifications",
			{Authorization: "asdasdasdsadsda"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should get notifications" do
		first_notification = notifications(:mattCardsFirstNotification)
		second_notification = notifications(:mattCardsSecondNotification)

		res = get_request(
			"/v1/notifications",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200
		assert_equal(2, res["notifications"].length)

		assert_equal(first_notification.id, res["notifications"][0]["id"])
		assert_equal(first_notification.user_id, res["notifications"][0]["user_id"])
		assert_equal(first_notification.app_id, res["notifications"][0]["app_id"])
		assert_equal(first_notification.uuid, res["notifications"][0]["uuid"])
		assert_equal(first_notification.time.to_i, res["notifications"][0]["time"])
		assert_equal(first_notification.interval, res["notifications"][0]["interval"])
		assert_equal(first_notification.title, res["notifications"][0]["title"])
		assert_equal(first_notification.body, res["notifications"][0]["body"])

		assert_equal(second_notification.id, res["notifications"][1]["id"])
		assert_equal(second_notification.user_id, res["notifications"][1]["user_id"])
		assert_equal(second_notification.app_id, res["notifications"][1]["app_id"])
		assert_equal(second_notification.uuid, res["notifications"][1]["uuid"])
		assert_equal(second_notification.time.to_i, res["notifications"][1]["time"])
		assert_equal(second_notification.interval, res["notifications"][1]["interval"])
		assert_equal(second_notification.title, res["notifications"][1]["title"])
		assert_equal(second_notification.body, res["notifications"][1]["body"])
	end

	# update_notification
	it "should not update notification without access token" do
		res = put_request("/v1/notification/23234234")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not update notification without Content-Type json" do
		res = put_request(
			"/v1/notification/20234j23",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not update notification with access token with session that does not exist" do
		res = put_request(
			"/v1/notification/asdasdasd",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update notification with properties with wrong types" do
		notification = notifications(:mattCardsFirstNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				time: true,
				interval: "Hello World",
				title: 123.4,
				body: false
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::TIME_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::INTERVAL_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::TITLE_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::BODY_WRONG_TYPE, res["errors"][3]["code"])
	end

	it "should not update notification with too short properties" do
		notification = notifications(:mattCardsFirstNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				title: "a",
				body: "a"
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::TITLE_TOO_SHORT, res["errors"][0]["code"])
		assert_equal(ErrorCodes::BODY_TOO_SHORT, res["errors"][1]["code"])
	end

	it "should not update notification with too long properties" do
		notification = notifications(:mattCardsFirstNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				title: "a" * 200,
				body: "a" * 200
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::TITLE_TOO_LONG, res["errors"][0]["code"])
		assert_equal(ErrorCodes::BODY_TOO_LONG, res["errors"][1]["code"])
	end

	it "should not update notification that does not exist" do
		res = put_request(
			"/v1/notification/ioahsd9h83q9dasd",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				interval: 0
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NOTIFICATION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update notification that does not belong to the user" do
		notification = notifications(:mattCardsFirstNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:davCardsSession).token, 'Content-Type': 'application/json'},
			{
				interval: 0
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update notification that does not belong to the app" do
		notification = notifications(:mattCardsFirstNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:mattWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				interval: 0
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should update notification" do
		notification = notifications(:mattCardsFirstNotification)
		time = Time.now.to_i
		interval = 13123123
		title = "Updated title"
		body = "Updated body"

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				time: time,
				interval: interval,
				title: title,
				body: body
			}
		)

		assert_response 200
		
		assert_equal(notification.id, res["id"])
		assert_equal(notification.user_id, res["user_id"])
		assert_equal(notification.app_id, res["app_id"])
		assert_equal(notification.uuid, res["uuid"])
		assert_equal(time, res["time"])
		assert_equal(interval, res["interval"])
		assert_equal(title, res["title"])
		assert_equal(body, res["body"])

		notification = Notification.find_by(id: notification.id)
		assert_not_nil(notification)
		assert_equal(notification.id, res["id"])
		assert_equal(notification.user_id, res["user_id"])
		assert_equal(notification.app_id, res["app_id"])
		assert_equal(notification.uuid, res["uuid"])
		assert_equal(notification.time.to_i, res["time"])
		assert_equal(notification.interval, res["interval"])
		assert_equal(notification.title, res["title"])
		assert_equal(notification.body, res["body"])
	end

	# delete_notification
	it "should not delete notification without access token" do
		res = delete_request("/v1/notification/asdasdsad")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not delete notification with access token for session that does not exist" do
		res = delete_request(
			"/v1/notification/pjadpiasdjasd",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not delete notificaion that does not exist" do
		res = delete_request(
			"/v1/notification/asdasd234fdaf3r",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NOTIFICATION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not delete notification that does not belong to the user" do
		notification = notifications(:mattCardsFirstNotification)

		res = delete_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:davCardsSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not delete notification that does not belong to the app" do
		notification = notifications(:mattCardsFirstNotification)

		res = delete_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:mattWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should delete notification" do
		notification = notifications(:mattCardsFirstNotification)

		res = delete_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 204

		notification = Notification.find_by(id: notification.id)
		assert_nil(notification)
	end
end