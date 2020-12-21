require "test_helper"

describe TablesController do
	setup do
		setup
	end

	# create_table
	it "should not create table without jwt" do
		res = post_request("/v1/table")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not create table without Content-Type json" do
		res = post_request(
			"/v1/table",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create table with invalid jwt" do
		res = post_request(
			"/v1/table",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create table with jwt for app that is not the website" do
		jwt = generate_jwt(sessions(:mattTestAppSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create table without required properties" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::APP_ID_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::NAME_MISSING, res["errors"][1]["code"])
	end

	it "should not create table with properties with wrong types" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: "hello",
				name: 123
			}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::APP_ID_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::NAME_WRONG_TYPE, res["errors"][1]["code"])
	end

	it "should not create table for app that does not exist" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: -12,
				name: "TestTable"
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::APP_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create table for app that does not belong to the dev of the app" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: apps(:cards).id,
				name: "TestTable"
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create table with too short name" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: apps(:pocketlib).id,
				name: "a"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not create table with too long name" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: apps(:pocketlib).id,
				name: "a" * 50
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NAME_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not create table with invalid name" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: apps(:pocketlib).id,
				name: "test table 123"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NAME_INVALID, res["errors"][0]["code"])
	end

	it "should create table" do
		jwt = generate_jwt(sessions(:davWebsiteSession))
		app_id = apps(:pocketlib).id
		name = "TestTable"

		res = post_request(
			"/v1/table",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				app_id: app_id,
				name: name
			}
		)

		assert_response 201
		assert_not_nil(res["id"])
		assert_equal(app_id, res["app_id"])
		assert_equal(name, res["name"])

		table = Table.find_by(id: res["id"])
		assert_not_nil(table)
		assert_equal(table.id, res["id"])
		assert_equal(app_id, res["app_id"])
		assert_equal(name, res["name"])
	end
end