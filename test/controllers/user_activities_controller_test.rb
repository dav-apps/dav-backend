require "test_helper"

describe UserActivitiesController do
	setup do
		setup
	end

	# get_user_activities
	it "should not get user activities without access token" do
		res = get_request("/v1/user_activities")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get user activities with access token of session that does not exist" do
		res = get_request(
			"/v1/user_activities",
			{Authorization: "asdasdasdasdads"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get user activities from another app than the website" do
		res = get_request(
			"/v1/user_activities",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get user activities with another dev than the first one" do
		res = get_request(
			"/v1/user_activities",
			{Authorization: sessions(:davWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get user activities if the user is not a dev" do
		res = get_request(
			"/v1/user_activities",
			{Authorization: sessions(:mattWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get user activities" do
		first_user_activity = UserActivity.create(
			time: (Time.now - 3.days).beginning_of_day,
			count_daily: 3,
			count_monthly: 9,
			count_yearly: 20
		)
		second_user_activity = UserActivity.create(
			time: (Time.now - 20.days).beginning_of_day,
			count_daily: 4,
			count_monthly: 7,
			count_yearly: 18
		)

		res = get_request(
			"/v1/user_activities",
			{Authorization: sessions(:sherlockWebsiteSession).token}
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

	it "should get user activities in the specified timeframe" do
		start_timestamp = DateTime.parse("2019-06-09T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2019-06-12T00:00:00.000Z").to_i
		first_user_activity = user_activities(:first_user_activity)
		second_user_activity = user_activities(:second_user_activity)

		res = get_request(
			"/v1/user_activities?start=#{start_timestamp}&end=#{end_timestamp}",
			{Authorization: sessions(:sherlockWebsiteSession).token}
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