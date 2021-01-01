require "test_helper"

describe NotificationsController do
	setup do
		setup
	end

	# create_notification
	it "should not create notification without jwt" do
		res = post_request("/v1/notification")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
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

	it "should not create notification with invalid jwt" do
		res = post_request(
			"/v1/notification",
			{Authorization: "asdasdsad", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not create notification without required properties" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::TIME_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::INTERVAL_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::TITLE_MISSING, res["errors"][2]["code"])
		assert_equal(ErrorCodes::BODY_MISSING, res["errors"][3]["code"])
	end

	it "should not create notification with properties with wrong types" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(session)
		time = (Time.now - 1.month).to_i
		interval = 1.day.to_i
		title = "Hello World"
		body = "This is a test notification"

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(session)
		uuid = SecureRandom.uuid
		time = (Time.now - 1.month).to_i
		interval = 1.day.to_i
		title = "Hello World"
		body = "This is a test notification"

		res = post_request(
			"/v1/notification",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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

	# update_notification
	it "should not update notification without jwt" do
		res = put_request("/v1/notification/23234234")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
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

	it "should not update notification with invalid jwt" do
		res = put_request(
			"/v1/notification/asdasdasd",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not update notification with properties with wrong types" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/notification/ioahsd9h83q9dasd",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				interval: 0
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NOTIFICATION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update notification that does not belong to the user" do
		jwt = generate_jwt(sessions(:davCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				interval: 0
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update notification that does not belong to the app" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				interval: 0
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should update notification" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)
		time = Time.now.to_i
		interval = 13123123
		title = "Updated title"
		body = "Updated body"

		res = put_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
	it "should not delete notification without jwt" do
		res = delete_request("/v1/notification/asdasdsad")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not delete notification with invalid jwt" do
		res = delete_request(
			"/v1/notification/pjadpiasdjasd",
			{Authorization: "asdasdasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not delete notificaion that does not exist" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = delete_request(
			"/v1/notification/asdasd234fdaf3r",
			{Authorization: jwt}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NOTIFICATION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not delete notification that does not belong to the user" do
		jwt = generate_jwt(sessions(:davCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = delete_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not delete notification that does not belong to the app" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = delete_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should delete notification" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		notification = notifications(:mattCardsFirstReminderNotification)

		res = delete_request(
			"/v1/notification/#{notification.uuid}",
			{Authorization: jwt}
		)

		assert_response 204

		notification = Notification.find_by(id: notification.id)
		assert_nil(notification)
	end
end