require "test_helper"

describe TableObjectsController do
	setup do
		setup
	end

	# create_table_object
	it "should not create table object without access token" do
		res = post_request("/v1/table_object")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not create table object without Content-Type json" do
		res = post_request(
			"/v1/table_object",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not create table object with access token for session that does not exist" do
		res = post_request(
			"/v1/table_object",
			{Authorization: "asdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create table object without required properties" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_MISSING, res["errors"][0]["code"])
	end

	it "should not create table object with properties with wrong types" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: "142"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not create table object with optional properties with wrong types" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				uuid: 123,
				table_id: "142",
				file: "wqqwew",
				properties: true
			}
		)

		assert_response 400
		assert_equal(4, res["errors"].length)
		assert_equal(ErrorCodes::UUID_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::TABLE_ID_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::FILE_WRONG_TYPE, res["errors"][2]["code"])
		assert_equal(ErrorCodes::PROPERTIES_WRONG_TYPE, res["errors"][3]["code"])
	end

	it "should not create table object for table that does not exist" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: -12
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create table object for table of app of another dev" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:storeBook).id
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create table object for table that does not belong to the app of the session" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattTestAppSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:storeBook).id
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create table object with uuid that is already in use" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				uuid: table_objects(:davSecondCard).uuid
			}
		)

		assert_response 409
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::UUID_ALREADY_TAKEN, res["errors"][0]["code"])
	end

	it "should not create table object as file with ext with wrong type" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				file: true,
				properties: {
					ext: 123
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EXT_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not create table object with too short property name" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				properties: {
					"": "Hello World",
					"test": "Hallo Welt"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_NAME_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not create table object with too long property name" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				properties: {
					"test": "Hallo Welt",
					"#{'a' * 240}": "Hello World"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_NAME_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not create table object with too short property value" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				properties: {
					"page1": "",
					"page2": "Hello World"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_VALUE_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not create table object with too long property value" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				properties: {
					"page1": "Hello World",
					"page2": "#{'a' * 65100}"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_VALUE_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not create table object as file with too short ext" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				file: true,
				properties: {
					ext: ""
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EXT_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not create table object as file with too long ext" do
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				file: true,
				properties: {
					ext: "asdasdasd"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EXT_TOO_LONG, res["errors"][0]["code"])
	end

	it "should create table object" do
		table = tables(:card)
		first_property_name = "test1"
		first_property_value = "Hello World"
		second_property_name = "test2"
		second_property_value = 123
		third_property_name = "test3"
		third_property_value = 53.23
		fourth_property_name = "test4"
		fourth_property_value = true

		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id,
				properties: {
					"#{first_property_name}": first_property_value,
					"#{second_property_name}": second_property_value,
					"#{third_property_name}": third_property_value,
					"testtest": nil,
					"#{fourth_property_name}": fourth_property_value
				}
			}
		)

		assert_response 201

		table_object = TableObject.find_by(id: res["id"])
		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(table_object.etag, res["etag"])
		assert_equal(table_object.table_object_properties.length, res["properties"].length)

		assert_equal(users(:matt).id, res["user_id"])
		assert_equal(tables(:card).id, res["table_id"])
		assert_not_nil(res["uuid"])
		assert(!res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(4, res["properties"].length)

		# First property
		assert_equal(res["properties"][first_property_name], first_property_value)

		first_property = TableObjectProperty.find_by(table_object: table_object, name: first_property_name)
		assert_not_nil(first_property)
		assert_equal(first_property_value.to_s, first_property.value)

		first_property_type = TablePropertyType.find_by(table: table, name: first_property_name)
		assert_not_nil(first_property_type)
		assert_equal(0, first_property_type.data_type)

		# Second property
		assert_equal(res["properties"][second_property_name], second_property_value)

		second_property = TableObjectProperty.find_by(table_object: table_object, name: second_property_name)
		assert_not_nil(second_property)
		assert_equal(second_property_value.to_s, second_property.value)

		second_property_type = TablePropertyType.find_by(table: table, name: second_property_name)
		assert_not_nil(second_property_type)
		assert_equal(2, second_property_type.data_type)

		# Third property
		assert_equal(res["properties"][third_property_name], third_property_value)

		third_property = TableObjectProperty.find_by(table_object: table_object, name: third_property_name)
		assert_not_nil(third_property)
		assert_equal(third_property_value.to_s, third_property.value)

		third_property_type = TablePropertyType.find_by(table: table, name: third_property_name)
		assert_not_nil(third_property_type)
		assert_equal(3, third_property_type.data_type)

		# Fourth property
		assert_equal(res["properties"][fourth_property_name], fourth_property_value)

		fourth_property = TableObjectProperty.find_by(table_object: table_object, name: fourth_property_name)
		assert_not_nil(fourth_property)
		assert_equal(fourth_property_value.to_s, fourth_property.value)

		fourth_property_type = TablePropertyType.find_by(table: table, name: fourth_property_name)
		assert_not_nil(fourth_property_type)
		assert_equal(1, fourth_property_type.data_type)
	end

	it "should create table object with uuid" do
		table = tables(:card)
		uuid = SecureRandom.uuid
		first_property_name = "test1"
		first_property_value = "Hello World"
		second_property_name = "test2"
		second_property_value = 123
		third_property_name = "test3"
		third_property_value = 53.23
		fourth_property_name = "test4"
		fourth_property_value = true

		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id,
				uuid: uuid,
				properties: {
					"#{first_property_name}": first_property_value,
					"#{second_property_name}": second_property_value,
					"#{third_property_name}": third_property_value,
					"testtest": nil,
					"#{fourth_property_name}": fourth_property_value
				}
			}
		)

		assert_response 201

		table_object = TableObject.find_by(id: res["id"])
		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(table_object.etag, res["etag"])
		assert_equal(table_object.table_object_properties.length, res["properties"].length)

		assert_equal(users(:matt).id, res["user_id"])
		assert_equal(tables(:card).id, res["table_id"])
		assert_equal(uuid, res["uuid"])
		assert(!res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(4, res["properties"].length)

		# First property
		assert_equal(res["properties"][first_property_name], first_property_value)

		first_property = TableObjectProperty.find_by(table_object: table_object, name: first_property_name)
		assert_not_nil(first_property)
		assert_equal(first_property_value.to_s, first_property.value)

		first_property_type = TablePropertyType.find_by(table: table, name: first_property_name)
		assert_not_nil(first_property_type)
		assert_equal(0, first_property_type.data_type)

		# Second property
		assert_equal(res["properties"][second_property_name], second_property_value)

		second_property = TableObjectProperty.find_by(table_object: table_object, name: second_property_name)
		assert_not_nil(second_property)
		assert_equal(second_property_value.to_s, second_property.value)

		second_property_type = TablePropertyType.find_by(table: table, name: second_property_name)
		assert_not_nil(second_property_type)
		assert_equal(2, second_property_type.data_type)

		# Third property
		assert_equal(res["properties"][third_property_name], third_property_value)

		third_property = TableObjectProperty.find_by(table_object: table_object, name: third_property_name)
		assert_not_nil(third_property)
		assert_equal(third_property_value.to_s, third_property.value)

		third_property_type = TablePropertyType.find_by(table: table, name: third_property_name)
		assert_not_nil(third_property_type)
		assert_equal(3, third_property_type.data_type)

		# Fourth property
		assert_equal(res["properties"][fourth_property_name], fourth_property_value)

		fourth_property = TableObjectProperty.find_by(table_object: table_object, name: fourth_property_name)
		assert_not_nil(fourth_property)
		assert_equal(fourth_property_value.to_s, fourth_property.value)

		fourth_property_type = TablePropertyType.find_by(table: table, name: fourth_property_name)
		assert_not_nil(fourth_property_type)
		assert_equal(1, fourth_property_type.data_type)
	end

	it "should create table object without properties" do
		table = tables(:card)
		
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id
			}
		)

		assert_response 201

		table_object = TableObject.find_by(id: res["id"])
		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(table_object.etag, res["etag"])
		assert_equal(table_object.table_object_properties.length, res["properties"].length)

		assert_equal(users(:matt).id, res["user_id"])
		assert_equal(tables(:card).id, res["table_id"])
		assert_not_nil(res["uuid"])
		assert(!res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(0, res["properties"].length)

		properties = TableObjectProperty.where(table_object: table_object)
		assert_equal(0, properties.length)
	end

	it "should create table object with uuid without properties" do
		table = tables(:card)
		uuid = SecureRandom.uuid
		
		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id,
				uuid: uuid
			}
		)

		assert_response 201

		table_object = TableObject.find_by(id: res["id"])
		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(table_object.etag, res["etag"])
		assert_equal(table_object.table_object_properties.length, res["properties"].length)

		assert_equal(users(:matt).id, res["user_id"])
		assert_equal(tables(:card).id, res["table_id"])
		assert_equal(uuid, res["uuid"])
		assert(!res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(0, res["properties"].length)

		properties = TableObjectProperty.where(table_object: table_object)
		assert_equal(0, properties.length)
	end

	it "should create table object as file" do
		table = tables(:card)

		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id,
				file: true,
				properties: {
					"page1": "Hello World",
					"page2": "Hallo Welt"
				}
			}
		)

		assert_response 201

		table_object = TableObject.find_by(id: res["id"])
		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(table_object.etag, res["etag"])
		assert_equal(table_object.table_object_properties.length, res["properties"].length)

		assert_equal(users(:matt).id, res["user_id"])
		assert_equal(tables(:card).id, res["table_id"])
		assert_not_nil(res["uuid"])
		assert(res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(0, res["properties"].length)

		properties = TableObjectProperty.where(table_object: table_object)
		assert_equal(0, properties.length)
	end

	it "should create table object with uuid as file" do
		table = tables(:card)
		uuid = SecureRandom.uuid

		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id,
				uuid: uuid,
				file: true,
				properties: {
					"page1": "Hello World",
					"page2": "Hallo Welt"
				}
			}
		)

		assert_response 201

		table_object = TableObject.find_by(id: res["id"])
		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(table_object.etag, res["etag"])
		assert_equal(table_object.table_object_properties.length, res["properties"].length)

		assert_equal(users(:matt).id, res["user_id"])
		assert_equal(tables(:card).id, res["table_id"])
		assert_equal(uuid, res["uuid"])
		assert(res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(0, res["properties"].length)

		properties = TableObjectProperty.where(table_object: table_object)
		assert_equal(0, properties.length)
	end

	it "should create table object as file with ext" do
		table = tables(:testTable)
		ext = "mp4"

		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id,
				file: true,
				properties: {
					ext: ext
				}
			}
		)

		assert_response 201

		table_object = TableObject.find_by(id: res["id"])
		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(table_object.etag, res["etag"])
		assert_equal(table_object.table_object_properties.length, res["properties"].length)

		assert_equal(users(:sherlock).id, res["user_id"])
		assert_equal(table.id, res["table_id"])
		assert_not_nil(res["uuid"])
		assert(res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(1, res["properties"].length)

		ext_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::EXT_PROPERTY_NAME)
		assert_not_nil(ext_property)
		assert_equal(ext, ext_property.value)
	end

	it "should create table object and update last_active fields" do
		table = tables(:card)

		res = post_request(
			"/v1/table_object",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_id: table.id,
				properties: {
					"page1": "Hello World",
					"page2": "Hallo Welt"
				}
			}
		)

		assert_response 201

		user = users(:matt)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:mattCards)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end

	# get_table_object
	it "should not get table object without access token" do
		res = get_request(
			"/v1/table_object/sdfsdfsfd"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get table object with access token of session that does not exist" do
		res = get_request(
			"/v1/table_object/dfsdfsdf",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table object that does not exist" do
		res = get_request(
			"/v1/table_object/sdoisfjdosdijf",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table object that belongs to another user" do
		res = get_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).uuid}",
			{Authorization: sessions(:davCardsSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get table object with session that does not belong to the app" do
		res = get_request(
			"/v1/table_object/#{table_objects(:davFirstCard).uuid}",
			{Authorization: sessions(:davWebsiteSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get table object" do
		table_object = table_objects(:sherlockTestData)

		res = get_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(4, res["properties"].length)

		first_property = table_object.table_object_properties.where(name: "test1").first
		assert_equal(first_property.value, res["properties"][first_property.name])
		assert(res["properties"][first_property.name].is_a?(String))

		second_property = table_object.table_object_properties.where(name: "test2").first
		assert_equal(second_property.value == "true", res["properties"][second_property.name])
		assert(res["properties"][second_property.name].is_a?(TrueClass))

		third_property = table_object.table_object_properties.where(name: "test3").first
		assert_equal(third_property.value.to_i, res["properties"][third_property.name])
		assert(res["properties"][third_property.name].is_a?(Integer))

		fourth_property = table_object.table_object_properties.where(name: "test4").first
		assert_equal(fourth_property.value.to_f, res["properties"][fourth_property.name])
		assert(res["properties"][fourth_property.name].is_a?(Float))
	end

	it "should get table object with access" do
		table_object = table_objects(:davFirstCard)

		res = get_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(2, res["properties"].length)

		first_property = table_object.table_object_properties.where(name: "page1").first
		assert_equal(first_property.value, res["properties"][first_property.name])
		assert(res["properties"][first_property.name].is_a?(String))

		second_property = table_object.table_object_properties.where(name: "page2").first
		assert_equal(second_property.value, res["properties"][second_property.name])
		assert(res["properties"][second_property.name].is_a?(String))
	end

	it "should get table object and update last_active fields" do
		table_object = table_objects(:sherlockTestData)

		res = get_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 200

		user = users(:sherlock)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:sherlockTestApp)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end

	# update_table_object
	it "should not update table object without access token" do
		res = put_request(
			"/v1/table_object/sadasdasd"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not update table object without Content-Type json" do
		res = put_request(
			"/v1/table_object/sdfsdfsdfsfd",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not update table object with access token of session that does not exist" do
		res = put_request(
			"/v1/table_object/sdgsdgsdg",
			{Authorization: "asdasdasds", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update table object without properties" do
		res = put_request(
			"/v1/table_object/gsdsgsdgsdg",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTIES_MISSING, res["errors"][0]["code"])
	end

	it "should not update table object with properties with wrong type" do
		res = put_request(
			"/v1/table_object/sdgsdgsdgsdg",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: "hello"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTIES_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not update table object that does not exist" do
		res = put_request(
			"/v1/table_object/sdgsdgsdgsdg",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {}
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update table object that belongs to another user" do
		res = put_request(
			"/v1/table_object/#{table_objects(:davSecondCard).uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {}
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update table object with session that does not belong to the app" do
		res = put_request(
			"/v1/table_object/#{table_objects(:davFirstCard).uuid}",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': 'application/json'},
			{
				properties: {}
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update file table object with ext with wrong type" do
		res = put_request(
			"/v1/table_object/#{table_objects(:sherlockTestFile).uuid}",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					ext: false
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EXT_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not update table object with too short property name" do
		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					test1: "Test",
					"": "Test 2"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_NAME_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not update table object with too long property name" do
		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					test1: "Test",
					"#{'a' * 220}": "Test 2"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_NAME_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not update table object with too short property value" do
		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					test1: "Test",
					test2: ""
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_VALUE_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not update table object with too long property value" do
		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					test1: "Test",
					test2: "#{'a' * 65200}"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTY_VALUE_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not update file table object with too short ext" do
		res = put_request(
			"/v1/table_object/#{table_objects(:sherlockTestFile).uuid}",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					ext: ""
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EXT_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not update file table object with too long ext" do
		res = put_request(
			"/v1/table_object/#{table_objects(:sherlockTestFile).uuid}",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					ext: "asdasdasdasd"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::EXT_TOO_LONG, res["errors"][0]["code"])
	end

	it "should update table object" do
		table = tables(:card)
		table_object = table_objects(:mattSecondCard)
		first_property_name = table_object_properties(:mattSecondCardPage1).name
		first_property_value = table_object_properties(:mattSecondCardPage1).value
		second_property_name = "page2"
		second_property_value = "Updated value"
		third_property_name = "page3"
		third_property_value = "New value"
		fourth_property_name = "page4"
		fourth_property_value = 123
		fifth_property_name = "page5"
		fifth_property_value = false

		res = put_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					"#{second_property_name}": second_property_value,
					"#{third_property_name}": third_property_value,
					"#{fourth_property_name}": fourth_property_value,
					"#{fifth_property_name}": fifth_property_value
				}
			}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(5, res["properties"].length)

		# First property
		assert_equal(res["properties"][first_property_name], first_property_value)

		first_property = TableObjectProperty.find_by(table_object: table_object, name: first_property_name)
		assert_not_nil(first_property)
		assert_equal(first_property_value, first_property.value)

		first_property_type = TablePropertyType.find_by(table: table, name: first_property_name)
		assert_not_nil(first_property_type)
		assert_equal(0, first_property_type.data_type)

		# Second property
		assert_equal(res["properties"][second_property_name], second_property_value)

		second_property = TableObjectProperty.find_by(table_object: table_object, name: second_property_name)
		assert_not_nil(second_property)
		assert_equal(second_property_value, second_property.value)

		second_property_type = TablePropertyType.find_by(table: table, name: second_property_name)
		assert_not_nil(second_property_type)
		assert_equal(0, second_property_type.data_type)

		# Third property
		assert_equal(res["properties"][third_property_name], third_property_value)

		third_property = TableObjectProperty.find_by(table_object: table_object, name: third_property_name)
		assert_not_nil(third_property)
		assert_equal(third_property_value, third_property.value)

		third_property_type = TablePropertyType.find_by(table: table, name: third_property_name)
		assert_not_nil(third_property_type)
		assert_equal(0, third_property_type.data_type)

		# Fourth property
		assert_equal(res["properties"][fourth_property_name], fourth_property_value)
		
		fourth_property = TableObjectProperty.find_by(table_object: table_object, name: fourth_property_name)
		assert_not_nil(fourth_property)
		assert_equal(fourth_property_value.to_s, fourth_property.value)

		fourth_property_type = TablePropertyType.find_by(table: table, name: fourth_property_name)
		assert_not_nil(fourth_property_type)
		assert_equal(2, fourth_property_type.data_type)

		# Fifth_property
		assert_equal(res["properties"][fifth_property_name], fifth_property_value)

		fifth_property = TableObjectProperty.find_by(table_object: table_object, name: fifth_property_name)
		assert_not_nil(fifth_property)
		assert_equal(fifth_property_value.to_s, fifth_property.value)

		fifth_property_type = TablePropertyType.find_by(table: table, name: fifth_property_name)
		assert_not_nil(fifth_property_type)
		assert_equal(1, fifth_property_type.data_type)
	end

	it "should update table object and remove properties using nil" do
		table_object = table_objects(:mattSecondCard)
		first_property_name = table_object_properties(:mattSecondCardPage1).name
		second_property_name = table_object_properties(:mattSecondCardPage2).name
		second_property_value = table_object_properties(:mattSecondCardPage2).value

		res = put_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					"#{first_property_name}": nil
				}
			}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(1, res["properties"].length)

		# First property
		first_property = TableObjectProperty.find_by(table_object: table_object, name: first_property_name)
		assert_nil(first_property)

		# Second property
		assert_equal(res["properties"][second_property_name], second_property_value)

		second_property = TableObjectProperty.find_by(table_object: table_object, name: second_property_name)
		assert_not_nil(second_property)
		assert_equal(second_property_value, second_property.value)

		second_property_type = TablePropertyType.find_by(table: table_object.table, name: second_property_name)
		assert_not_nil(second_property_type)
		assert_equal(0, second_property_type.data_type)
	end

	it "should update file table object with ext" do
		table_object = table_objects(:sherlockTestFile)
		ext = "mp3"

		res = put_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': 'application/json'},
			{
				properties: {
					ext: ext
				}
			}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(1, res["properties"].length)

		# Ext property
		ext_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::EXT_PROPERTY_NAME)
		assert_not_nil(ext)
		assert_equal(ext, ext_property.value)
	end

	it "should update table object and update last_active fields" do
		table_object = table_objects(:mattSecondCard)

		res = put_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				properties: {}
			}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(2, res["properties"].length)

		user = users(:matt)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:mattCards)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end

	# delete_table_object
	it "should not delete table object without access token" do
		res = delete_request(
			"/v1/table_object/afasfsafsaf"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not delete table object with access token of session that does not exist" do
		res = delete_request(
			"/v1/table_object/asdasdasd",
			{Authorization: "asdasdasd.asdasd.sda"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not delete table object that does not exist" do
		res = delete_request(
			"/v1/table_object/adssadasdasd",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should delete table object" do
		table_object = table_objects(:mattSecondCard)
		first_property = table_object_properties(:mattSecondCardPage1)
		second_property = table_object_properties(:mattSecondCardPage2)

		res = delete_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 204

		obj = TableObject.find_by(id: table_object.id)
		assert_nil(obj)

		prop1 = TableObjectProperty.find_by(id: first_property.id)
		assert_nil(prop1)
		
		prop2 = TableObjectProperty.find_by(id: second_property.id)
		assert_nil(prop2)
	end

	it "should delete table object and update last_active fields" do
		table_object = table_objects(:mattSecondCard)

		res = delete_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 204

		user = users(:matt)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:mattCards)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end

	it "should delete table object with file" do
		table_object = table_objects(:sherlockTestFile)

		# Upload a file for the table object
		upload_blob(table_object, StringIO.new("Hello World"))

		res = delete_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 204

		# Check if the file was deleted
		begin
			download_blob(table_object)
		rescue => e
			assert(!e.nil?)
		end
	end

	# set_table_object_file
	it "should not set table object file without access token" do
		res = put_request(
			"/v1/table_object/asdasdasdasd/file"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set table object file with not supported content type" do
		res = put_request(
			"/v1/table_object/agassadsda/file",
			{Authorization: "ssdasdsasafsgd", 'Content-Type': "application/x-www-form-urlencoded"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set table object file with access token of session that does not exist" do
		res = put_request(
			"/v1/table_object/asdasdasdasd/file",
			{Authorization: "ssdasdsasafsgd", 'Content-Type': "audio/mpeg"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set table object file for table object that does not exist" do
		res = put_request(
			"/v1/table_object/asdasasd/file",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': "audio/mpeg"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set table object file for table object that is not a file" do
		table_object = table_objects(:mattThirdCard)

		res = put_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': "audio/mpeg"}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_IS_NOT_FILE, res["errors"][0]["code"])
	end

	it "should not set table object file for table object that belongs to another user" do
		res = put_request(
			"/v1/table_object/#{table_objects(:davSecondCard).uuid}/file",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': "audio/mpeg"}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not set table object file with session that does not belong to the app" do
		res = put_request(
			"/v1/table_object/#{table_objects(:davFirstCard).uuid}/file",
			{Authorization: sessions(:davWebsiteSession).token, 'Content-Type': "audio/mpeg"}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not set table object file if the user has not enough free storage" do
		table_object = table_objects(:sherlockTestFile)
		sherlock = users(:sherlock)
		sherlock.used_storage = 50000000000
		sherlock.save

		res = put_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': "audio/mpeg"}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::NO_SUFFICIENT_STORAGE_AVAILABLE, res["errors"][0]["code"])
	end

	it "should set table object file" do
		table_object = table_objects(:sherlockTestFile)
		file_content = "<h1>Hello World</h1>"
		content_type = "text/html"

		res = put_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': content_type},
			file_content
		)

		assert_response 200

		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert(res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(3, res["properties"].length)

		# Get the blob
		blob, content = BlobOperationsService.download_blob(table_object)
		assert_equal(content, file_content)

		# Size property
		size_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME)
		assert_not_nil(size_property)
		assert_equal(file_content.length.to_s, size_property.value)
		assert_equal(size_property.value, res["properties"]["size"])

		# Type property
		type_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::TYPE_PROPERTY_NAME)
		assert_not_nil(type_property)
		assert_equal(content_type, type_property.value)
		assert_equal(type_property.value, res["properties"]["type"])

		# Etag property
		etag_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::ETAG_PROPERTY_NAME)
		assert_not_nil(etag_property)
		assert_equal(blob.properties[:etag][1...blob.properties[:etag].size - 1], etag_property.value)
		assert_equal(etag_property.value, res["properties"]["etag"])

		# Delete the blob
		BlobOperationsService.delete_blob(table_object)
	end

	it "should set table object file with binary data" do
		table_object = table_objects(:sherlockTestFile)
		file_content = File.open("test/fixtures/files/favicon.png", "rb").read
		content_type = "image/png"

		res = put_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': content_type},
			file_content
		)

		assert_response 200

		assert_not_nil(table_object)
		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert(res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(3, res["properties"].length)

		# Get the blob
		blob, content = BlobOperationsService.download_blob(table_object)
		assert_equal(content, file_content)

		# Size property
		size_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::SIZE_PROPERTY_NAME)
		assert_not_nil(size_property)
		assert_equal(file_content.length.to_s, size_property.value)
		assert_equal(size_property.value, res["properties"]["size"])

		# Type property
		type_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::TYPE_PROPERTY_NAME)
		assert_not_nil(type_property)
		assert_equal(content_type, type_property.value)
		assert_equal(type_property.value, res["properties"]["type"])

		# Etag property
		etag_property = TableObjectProperty.find_by(table_object: table_object, name: Constants::ETAG_PROPERTY_NAME)
		assert_not_nil(etag_property)
		assert_equal(blob.properties[:etag][1...blob.properties[:etag].size - 1], etag_property.value)
		assert_equal(etag_property.value, res["properties"]["etag"])

		# Delete the blob
		BlobOperationsService.delete_blob(table_object)
	end

	it "should set table object file and update last_active fields" do
		table_object = table_objects(:sherlockTestFile)
		file_content = "<h1>Hello World</h1>"
		content_type = "text/html"

		res = put_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': content_type},
			file_content
		)

		assert_response 200

		user = users(:sherlock)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:sherlockTestApp)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)

		# Delete the blob
		BlobOperationsService.delete_blob(table_object)
	end

	# get_table_object_file
	it "should not get table object file without access token" do
		res = get_request(
			"/v1/table_object/asdasdasd/file"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not get table object file with access token of session that does not exist" do
		res = get_request(
			"/v1/table_object/asdasdasdas/file",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table object file of table object that does not exist" do
		res = get_request(
			"/v1/table_object/aasfsafasfsfa/file",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table object file of table object that belongs to another user" do
		res = get_request(
			"/v1/table_object/#{table_objects(:davTestFile).uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get table object file with session that does not belong to the app" do
		res = get_request(
			"/v1/table_object/#{table_objects(:davTestFile).uuid}/file",
			{Authorization: sessions(:davCardsSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get table object file of table object that is not a file" do
		res = get_request(
			"/v1/table_object/#{table_objects(:davSecondCard).uuid}/file",
			{Authorization: sessions(:davCardsSession).token}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_IS_NOT_FILE, res["errors"][0]["code"])
	end

	it "should not get table object file of table object that has no file" do
		table_object = table_objects(:davTestFile)

		res = get_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:davTestAppSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_HAS_NO_FILE, res["errors"][0]["code"])
	end

	it "should get table object file" do
		# Set the file
		table_object = table_objects(:sherlockTestFile)
		file_content = "<h1>Hello World</h1>"
		content_type = "text/html"

		res = put_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': content_type},
			file_content
		)

		assert_response 200

		# Get the file
		res = get_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token},
			false
		)

		assert_response 200

		assert_equal(content_type, response.headers["Content-Type"])
		assert_equal(file_content.length, response.headers["Content-Length"].to_i)
		assert_equal(file_content, res)

		# Delete the blob
		BlobOperationsService.delete_blob(table_object)
	end

	it "should get table object file with binary data" do
		# Set the file
		table_object = table_objects(:sherlockTestFile)
		file_content = File.open("test/fixtures/files/favicon.png", "rb").read
		content_type = "image/png"

		res = put_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token, 'Content-Type': content_type},
			file_content
		)

		assert_response 200

		# Get the file
		res = get_request(
			"/v1/table_object/#{table_object.uuid}/file",
			{Authorization: sessions(:sherlockTestAppSession).token},
			false
		)

		assert_response 200

		assert_equal(content_type, response.headers["Content-Type"])
		assert_equal(file_content.length, response.headers["Content-Length"].to_i)
		assert_equal(file_content, res)

		# Delete the blob
		BlobOperationsService.delete_blob(table_object)
	end

	# add_table_object
	it "should not add table object without access token" do
		res = post_request("/v1/table_object/dsgosdoisdf/access")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not add table object without Content-Type json" do
		res = post_request(
			"/v1/table_object/lksdgksdgksgd/access",
			{Authorization: "asdasdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not add table object with access token of session that does not exist" do
		res = post_request(
			"/v1/table_object/sdfsdfjosdf/access",
			{Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not add table object with optional properties with wrong types" do
		res = post_request(
			"/v1/table_object/#{table_objects(:davFirstCard).uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_alias: "Hello World"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ALIAS_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not add table object that does not exist" do
		res = post_request(
			"/v1/table_object/papjasfpjoasf/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not add table object that belongs to another app" do
		res = post_request(
			"/v1/table_object/#{table_objects(:sherlockTestData).uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not add table object with alias table that does not exist" do
		res = post_request(
			"/v1/table_object/#{table_objects(:davFirstCard).uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_alias: -413
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not add table object with alias table that belongs to another app" do
		res = post_request(
			"/v1/table_object/#{table_objects(:davFirstCard).uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_alias: tables(:note).id
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not add table object that was already added" do
		table_object = table_objects(:davFirstCard)

		res = post_request(
			"/v1/table_object/#{table_object.uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_USER_ACCESS_ALREADY_EXISTS, res["errors"][0]["code"])
	end

	it "should add table object" do
		table_object = table_objects(:davThirdCard)

		res = post_request(
			"/v1/table_object/#{table_object.uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(table_object.table_id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(2, res["properties"].length)

		# First property
		first_property = table_object_properties(:davThirdCardPage1)
		assert_equal(first_property.value, res["properties"][first_property.name])

		# Second property
		second_property = table_object_properties(:davThirdCardPage2)
		assert_equal(second_property.value, res["properties"][second_property.name])
	end

	it "should add table object with table alias" do
		table_object = table_objects(:davThirdCard)
		alias_table = tables(:imageCard)

		res = post_request(
			"/v1/table_object/#{table_object.uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'},
			{
				table_alias: alias_table.id
			}
		)

		assert_response 200

		assert_equal(table_object.id, res["id"])
		assert_equal(table_object.user_id, res["user_id"])
		assert_equal(alias_table.id, res["table_id"])
		assert_equal(table_object.uuid, res["uuid"])
		assert_equal(table_object.file, res["file"])
		assert_equal(generate_table_object_etag(table_object), res["etag"])
		assert_equal(2, res["properties"].length)

		# First property
		first_property = table_object_properties(:davThirdCardPage1)
		assert_equal(first_property.value, res["properties"][first_property.name])

		# Second property
		second_property = table_object_properties(:davThirdCardPage2)
		assert_equal(second_property.value, res["properties"][second_property.name])
	end

	it "should add table object and update last_active fields" do
		table_object = table_objects(:davThirdCard)

		res = post_request(
			"/v1/table_object/#{table_object.uuid}/access",
			{Authorization: sessions(:mattCardsSession).token, 'Content-Type': 'application/json'}
		)

		assert_response 200

		user = users(:matt)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:mattCards)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end

	# remove_table_object
	it "should not remove table object without access token" do
		res = delete_request("/v1/table_object/iosdhiosdfio/access")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not remove table object with access token of session that does not exist" do
		res = delete_request(
			"/v1/table_object/asdasdasd/access",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not remove table object that does not exist" do
		res = delete_request(
			"/v1/table_object/gdpjodfpsjospodj/access",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not remove table object that belongs to another app" do
		res = delete_request(
			"/v1/table_object/#{table_objects(:davFirstCard).uuid}/access",
			{Authorization: sessions(:mattTestAppSession).token}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not remove table object that was not added" do
		res = delete_request(
			"/v1/table_object/#{table_objects(:davThirdCard).uuid}/access",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_USER_ACCESS_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should remove table object" do
		table_object = table_objects(:davFirstCard)

		res = delete_request(
			"/v1/table_object/#{table_object.uuid}/access",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 204

		access = TableObjectUserAccess.find_by(user: users(:matt), table_object: table_object)
		assert_nil(access)
	end

	it "should remove table object and update last_active fields" do
		table_object = table_objects(:davFirstCard)

		res = delete_request(
			"/v1/table_object/#{table_object.uuid}/access",
			{Authorization: sessions(:mattCardsSession).token}
		)

		assert_response 204

		user = users(:matt)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:mattCards)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end
end