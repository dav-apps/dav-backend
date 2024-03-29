require "test_helper"

describe TablesController do
	setup do
		setup
	end

	# create_table
	it "should not create table without access token" do
		res = post_request("/v1/table")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
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

	it "should not create table with access token of session that does not exist" do
		res = post_request(
			"/v1/table",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create table from another app than the website" do
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create table without required properties" do
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(2, res["errors"].length)
		assert_equal(ErrorCodes::APP_ID_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::NAME_MISSING, res["errors"][1]["code"])
	end

	it "should not create table with properties with wrong types" do
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
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
		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
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
		app_id = apps(:pocketlib).id
		name = "TestTable"

		res = post_request(
			"/v1/table",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
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

	# get_table
	it "should not get table without access token" do
		res = get_request(
			"/v1/table/1"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get table with access token for session that does not exist" do
		res = get_request(
			"/v1/table/1",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table that does not exist" do
		res = get_request(
			"/v1/table/-123",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table of app that does not belong to the dev" do
		res = get_request(
			"/v1/table/#{tables(:testTable).id}",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get table with session that does not belong to the app" do
		res = get_request(
			"/v1/table/#{tables(:card).id}",
			{Authorization: sessions(:davWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get table" do
		table = tables(:card)

		res = get_request(
			"/v1/table/#{table.id}",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200

		assert_equal(table.id, res["id"])
		assert_equal(table.app.id, res["app_id"])
		assert_equal(table.name, res["name"])
		assert_equal(1, res["pages"])
		assert_equal(table_etags(:mattCardEtag).etag, res["etag"])
		assert_equal(6, res["table_objects"].count)

		first_table_object = TableObject.find_by(uuid: res["table_objects"][0]["uuid"])
		assert_equal(first_table_object.uuid, res["table_objects"][0]["uuid"])
		assert_equal(generate_table_object_etag(first_table_object), res["table_objects"][0]["etag"])

		second_table_object = TableObject.find_by(uuid: res["table_objects"][1]["uuid"])
		assert_equal(second_table_object.uuid, res["table_objects"][1]["uuid"])
		assert_equal(generate_table_object_etag(second_table_object), res["table_objects"][1]["etag"])

		third_table_object = TableObject.find_by(uuid: res["table_objects"][2]["uuid"])
		assert_equal(third_table_object.uuid, res["table_objects"][2]["uuid"])
		assert_equal(generate_table_object_etag(third_table_object), res["table_objects"][2]["etag"])

		fourth_table_object = TableObject.find_by(uuid: res["table_objects"][3]["uuid"])
		assert_equal(fourth_table_object.uuid, res["table_objects"][3]["uuid"])
		assert_equal(generate_table_object_etag(fourth_table_object), res["table_objects"][3]["etag"])

		fifth_table_object = TableObject.find_by(uuid: res["table_objects"][4]["uuid"])
		assert_equal(fifth_table_object.uuid, res["table_objects"][4]["uuid"])
		assert_equal(generate_table_object_etag(fifth_table_object), res["table_objects"][4]["etag"])

		sixth_table_object = TableObject.find_by(uuid: res["table_objects"][5]["uuid"])
		assert_equal(sixth_table_object.uuid, res["table_objects"][5]["uuid"])
		assert_equal(generate_table_object_etag(sixth_table_object), res["table_objects"][5]["etag"])
	end

	it "should get table in multiple pages" do
		table = tables(:card)

		res = get_request(
			"/v1/table/#{table.id}?count=2",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200

		assert_equal(table.id, res["id"])
		assert_equal(table.app.id, res["app_id"])
		assert_equal(table.name, res["name"])
		assert_equal(3, res["pages"])
		assert_equal(2, res["table_objects"].count)

		first_table_object = TableObject.find_by(uuid: res["table_objects"][0]["uuid"])
		assert_equal(first_table_object.uuid, res["table_objects"][0]["uuid"])
		assert_equal(generate_table_object_etag(first_table_object), res["table_objects"][0]["etag"])

		second_table_object = TableObject.find_by(uuid: res["table_objects"][1]["uuid"])
		assert_equal(second_table_object.uuid, res["table_objects"][1]["uuid"])
		assert_equal(generate_table_object_etag(second_table_object), res["table_objects"][1]["etag"])

		res = get_request(
			"/v1/table/#{table.id}?count=2&page=2",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200

		assert_equal(table.id, res["id"])
		assert_equal(table.app.id, res["app_id"])
		assert_equal(table.name, res["name"])
		assert_equal(3, res["pages"])
		assert_equal(table_etags(:mattCardEtag).etag, res["etag"])
		assert_equal(2, res["table_objects"].count)

		third_table_object = TableObject.find_by(uuid: res["table_objects"][0]["uuid"])
		assert_equal(third_table_object.uuid, res["table_objects"][0]["uuid"])
		assert_equal(generate_table_object_etag(third_table_object), res["table_objects"][0]["etag"])

		fourth_table_object = TableObject.find_by(uuid: res["table_objects"][1]["uuid"])
		assert_equal(fourth_table_object.uuid, res["table_objects"][1]["uuid"])
		assert_equal(generate_table_object_etag(fourth_table_object), res["table_objects"][1]["etag"])

		res = get_request(
			"/v1/table/#{table.id}?count=2&page=3",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200

		assert_equal(table.id, res["id"])
		assert_equal(table.app.id, res["app_id"])
		assert_equal(table.name, res["name"])
		assert_equal(3, res["pages"])
		assert_equal(table_etags(:mattCardEtag).etag, res["etag"])
		assert_equal(2, res["table_objects"].count)

		fifth_table_object = TableObject.find_by(uuid: res["table_objects"][0]["uuid"])
		assert_equal(fifth_table_object.uuid, res["table_objects"][0]["uuid"])
		assert_equal(generate_table_object_etag(fifth_table_object), res["table_objects"][0]["etag"])

		sixth_table_object = TableObject.find_by(uuid: res["table_objects"][1]["uuid"])
		assert_equal(sixth_table_object.uuid, res["table_objects"][1]["uuid"])
		assert_equal(generate_table_object_etag(sixth_table_object), res["table_objects"][1]["etag"])
	end

	it "should get table and update last_active fields" do
		table = tables(:card)

		res = get_request(
			"/v1/table/#{table.id}?count=2",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200

		user = users(:matt)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:mattCards)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end
end