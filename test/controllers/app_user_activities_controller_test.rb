require "test_helper"

describe AppUserActivitiesController do
	setup do
		setup
	end

	# get_app_user_activities
	it "should not get app user activities without jwt" do
		res = get_request("/v1/app/1/user_activities")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get app user activities with invalid jwt" do
		res = get_request(
			"/v1/app/1/user_activities",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_INVALID, res["errors"][0]["code"])
	end

	it "should not get app user activities from another app than the website" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = get_request(
			"/v1/app/1/user_activities",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app user activities for the app of another dev" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))

		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}/user_activities",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app user activities if the user is not a dev" do
		jwt = generate_jwt(sessions(:mattWebsiteSession))

		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}/user_activities",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get app user activities" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))
		app = apps(:cards)
		first_user_activity = AppUserActivity.create(
			app: app,
			time: (Time.now - 3.days).beginning_of_day,
			count_daily: 3,
			count_monthly: 9,
			count_yearly: 20
		)
		second_user_activity = AppUserActivity.create(
			app: app,
			time: (Time.now - 20.days).beginning_of_day,
			count_daily: 4,
			count_monthly: 7,
			count_yearly: 18
		)

		res = get_request(
			"/v1/app/#{app.id}/user_activities",
			{Authorization: jwt}
		)

		assert_response 200
		assert_equal(2, res["days"].length)

		assert_equal(first_user_activity.time.to_s, res["days"][0]["time"])
		assert_equal(first_user_activity.count_daily, res["days"][0]["count_daily"])
		assert_equal(first_user_activity.count_monthly, res["days"][0]["count_monthly"])
		assert_equal(first_user_activity.count_yearly, res["days"][0]["count_yearly"])

		assert_equal(second_user_activity.time.to_s, res["days"][1]["time"])
		assert_equal(second_user_activity.count_daily, res["days"][1]["count_daily"])
		assert_equal(second_user_activity.count_monthly, res["days"][1]["count_monthly"])
		assert_equal(second_user_activity.count_yearly, res["days"][1]["count_yearly"])
	end

	it "should get app user activities in the specified timeframe" do
		jwt = generate_jwt(sessions(:sherlockWebsiteSession))
		app = apps(:cards)
		start_timestamp = DateTime.parse("2019-06-09T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2019-06-12T00:00:00.000Z").to_i
		first_user_activity = app_user_activities(:first_cards_user_activity)
		second_user_activity = app_user_activities(:second_cards_user_activity)

		res = get_request(
			"/v1/app/#{app.id}/user_activities?start=#{start_timestamp}&end=#{end_timestamp}",
			{Authorization: jwt}
		)

		assert_response 200
		assert_equal(2, res["days"].length)

		assert_equal(first_user_activity.time.to_s, res["days"][0]["time"])
		assert_equal(first_user_activity.count_daily, res["days"][0]["count_daily"])
		assert_equal(first_user_activity.count_monthly, res["days"][0]["count_monthly"])
		assert_equal(first_user_activity.count_yearly, res["days"][0]["count_yearly"])

		assert_equal(second_user_activity.time.to_s, res["days"][1]["time"])
		assert_equal(second_user_activity.count_daily, res["days"][1]["count_daily"])
		assert_equal(second_user_activity.count_monthly, res["days"][1]["count_monthly"])
		assert_equal(second_user_activity.count_yearly, res["days"][1]["count_yearly"])
	end
end