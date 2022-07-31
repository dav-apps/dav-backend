require "test_helper"

describe AppUserSnapshotsController do
	setup do
		setup
	end

	# get_app_user_snapshots
	it "should not get app user snapshots without access token" do
		res = get_request("/v1/app/1/user_snapshots")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get app user snapshots with access token for session that does not exist" do
		res = get_request(
			"/v1/app/1/user_snapshots",
			{Authorization: "asdasdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get app user snapshots from another app than the website" do
		res = get_request(
			"/v1/app/1/user_snapshots",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app user snapshots for the app of another dev" do
		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}/user_snapshots",
			{Authorization: sessions(:sherlockWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get app user snapshots if the user is not a dev" do
		res = get_request(
			"/v1/app/#{apps(:pocketlib).id}/user_snapshots",
			{Authorization: sessions(:mattWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get app user snapshots" do
		app = apps(:cards)
		first_user_snapshot = AppUserSnapshot.create(
			app: app,
			time: (Time.now - 3.days).beginning_of_day,
			daily_active: 3,
			weekly_active: 5,
			monthly_active: 9,
			yearly_active: 20,
         free_plan: 23,
         plus_plan: 5,
         pro_plan: 2,
         email_confirmed: 43,
         email_unconfirmed: 12
		)
		second_user_snapshot = AppUserSnapshot.create(
			app: app,
			time: (Time.now - 20.days).beginning_of_day,
			daily_active: 4,
			weekly_active: 2,
			monthly_active: 7,
			yearly_active: 18,
         free_plan: 26,
         plus_plan: 2,
         pro_plan: 6,
         email_confirmed: 19,
         email_unconfirmed: 43
		)

		res = get_request(
			"/v1/app/#{app.id}/user_snapshots",
			{Authorization: sessions(:sherlockWebsiteSession).token}
		)

		assert_response 200
		assert_equal(2, res["snapshots"].length)

		assert_equal(first_user_snapshot.time.to_s, res["snapshots"][0]["time"])
		assert_equal(first_user_snapshot.daily_active, res["snapshots"][0]["daily_active"])
		assert_equal(first_user_snapshot.weekly_active, res["snapshots"][0]["weekly_active"])
		assert_equal(first_user_snapshot.monthly_active, res["snapshots"][0]["monthly_active"])
		assert_equal(first_user_snapshot.yearly_active, res["snapshots"][0]["yearly_active"])
      assert_equal(first_user_snapshot.free_plan, res["snapshots"][0]["free_plan"])
      assert_equal(first_user_snapshot.plus_plan, res["snapshots"][0]["plus_plan"])
      assert_equal(first_user_snapshot.pro_plan, res["snapshots"][0]["pro_plan"])
      assert_equal(first_user_snapshot.email_confirmed, res["snapshots"][0]["email_confirmed"])
      assert_equal(first_user_snapshot.email_unconfirmed, res["snapshots"][0]["email_unconfirmed"])

		assert_equal(second_user_snapshot.time.to_s, res["snapshots"][1]["time"])
		assert_equal(second_user_snapshot.daily_active, res["snapshots"][1]["daily_active"])
		assert_equal(second_user_snapshot.weekly_active, res["snapshots"][1]["weekly_active"])
		assert_equal(second_user_snapshot.monthly_active, res["snapshots"][1]["monthly_active"])
		assert_equal(second_user_snapshot.yearly_active, res["snapshots"][1]["yearly_active"])
      assert_equal(second_user_snapshot.free_plan, res["snapshots"][1]["free_plan"])
      assert_equal(second_user_snapshot.plus_plan, res["snapshots"][1]["plus_plan"])
      assert_equal(second_user_snapshot.pro_plan, res["snapshots"][1]["pro_plan"])
      assert_equal(second_user_snapshot.email_confirmed, res["snapshots"][1]["email_confirmed"])
      assert_equal(second_user_snapshot.email_unconfirmed, res["snapshots"][1]["email_unconfirmed"])
	end

	it "should get app user snapshots in the specified timeframe" do
		app = apps(:cards)
		start_timestamp = DateTime.parse("2019-06-09T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2019-06-12T00:00:00.000Z").to_i
		first_user_snapshot = app_user_snapshots(:first_cards_user_snapshot)
		second_user_snapshot = app_user_snapshots(:second_cards_user_snapshot)

		res = get_request(
			"/v1/app/#{app.id}/user_snapshots?start=#{start_timestamp}&end=#{end_timestamp}",
			{Authorization: sessions(:sherlockWebsiteSession).token}
		)

		assert_response 200
		assert_equal(2, res["snapshots"].length)

		assert_equal(first_user_snapshot.time.to_s, res["snapshots"][0]["time"])
		assert_equal(first_user_snapshot.daily_active, res["snapshots"][0]["daily_active"])
		assert_equal(first_user_snapshot.weekly_active, res["snapshots"][0]["weekly_active"])
		assert_equal(first_user_snapshot.monthly_active, res["snapshots"][0]["monthly_active"])
		assert_equal(first_user_snapshot.yearly_active, res["snapshots"][0]["yearly_active"])
      assert_equal(first_user_snapshot.free_plan, res["snapshots"][0]["free_plan"])
      assert_equal(first_user_snapshot.plus_plan, res["snapshots"][0]["plus_plan"])
      assert_equal(first_user_snapshot.pro_plan, res["snapshots"][0]["pro_plan"])
      assert_equal(first_user_snapshot.email_confirmed, res["snapshots"][0]["email_confirmed"])
      assert_equal(first_user_snapshot.email_unconfirmed, res["snapshots"][0]["email_unconfirmed"])

		assert_equal(second_user_snapshot.time.to_s, res["snapshots"][1]["time"])
		assert_equal(second_user_snapshot.daily_active, res["snapshots"][1]["daily_active"])
		assert_equal(second_user_snapshot.weekly_active, res["snapshots"][1]["weekly_active"])
		assert_equal(second_user_snapshot.monthly_active, res["snapshots"][1]["monthly_active"])
		assert_equal(second_user_snapshot.yearly_active, res["snapshots"][1]["yearly_active"])
      assert_equal(second_user_snapshot.free_plan, res["snapshots"][1]["free_plan"])
      assert_equal(second_user_snapshot.plus_plan, res["snapshots"][1]["plus_plan"])
      assert_equal(second_user_snapshot.pro_plan, res["snapshots"][1]["pro_plan"])
      assert_equal(second_user_snapshot.email_confirmed, res["snapshots"][1]["email_confirmed"])
      assert_equal(second_user_snapshot.email_unconfirmed, res["snapshots"][1]["email_unconfirmed"])
	end
end