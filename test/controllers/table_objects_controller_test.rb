require "test_helper"

describe TableObjectsController do
	setup do
		setup
	end

	# create_table_object
	it "should not create table object without jwt" do
		res = post_request("/v1/table_object")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
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

	it "should not create table object with invalid jwt" do
		res = post_request(
			"/v1/table_object",
			{Authorization: "asdasd", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create table object without required properties" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_MISSING, res["errors"][0]["code"])
	end

	
	it "should not create table object with properties with wrong types" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				table_id: "142"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not create table object with optional properties with wrong types" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				table_id: -12
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not create table object for table of app of another dev" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				table_id: tables(:storeBook).id
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create table object for table that does not belong to the app of the session" do
		jwt = generate_jwt(sessions(:mattTestAppSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				table_id: tables(:storeBook).id
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not create table object with uuid that is already in use" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				table_id: tables(:card).id,
				uuid: table_objects(:davSecondCard).uuid
			}
		)

		assert_response 409
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::UUID_ALREADY_TAKEN, res["errors"][0]["code"])
	end

	it "should not create table object with too short property name" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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

	it "should create table object" do
		jwt = generate_jwt(sessions(:mattCardsSession))
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
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
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
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		table = tables(:card)
		
		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		table = tables(:card)
		uuid = SecureRandom.uuid
		
		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		table = tables(:card)

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		table = tables(:card)
		uuid = SecureRandom.uuid

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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

	it "should create table object and update last_active fields" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		table = tables(:card)

		res = post_request(
			"/v1/table_object",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
	it "should not get table object without jwt" do
		res = get_request(
			"/v1/table_object/1"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not get table object with invalid jwt" do
		res = get_request(
			"/v1/table_object/1",
			{Authorization: "asdasdasd"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table object that does not exist" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = get_request(
			"/v1/table_object/-123",
			{Authorization: jwt}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not get table object that belongs to another user" do
		jwt = generate_jwt(sessions(:davCardsSession))

		res = get_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).id}",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not get table object with session that does not belong to the app" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = get_request(
			"/v1/table_object/#{table_objects(:davFirstCard).id}",
			{Authorization: jwt}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should get table object" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))
		table_object = table_objects(:sherlockTestData)

		res = get_request(
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt}
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

	it "should get table object with uuid" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))
		table_object = table_objects(:sherlockTestData)

		res = get_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: jwt}
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		table_object = table_objects(:davFirstCard)

		res = get_request(
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt}
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

	it "should get table with uuid with access" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		table_object = table_objects(:davFirstCard)

		res = get_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: jwt}
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
		jwt = generate_jwt(sessions(:sherlockTestAppSession))
		table_object = table_objects(:sherlockTestData)

		res = get_request(
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt}
		)

		assert_response 200

		user = users(:sherlock)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:sherlockTestApp)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end

	# update_table_object
	it "should not update table object without jwt" do
		res = put_request(
			"/v1/table_object/1"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not update table object without Content-Type json" do
		res = put_request(
			"/v1/table_object/1",
			{Authorization: "asdasd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not update table object with invalid jwt" do
		res = put_request(
			"/v1/table_object/1",
			{Authorization: "asdasdasds", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update table object without properties" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/-413",
			{Authorization: jwt, 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTIES_MISSING, res["errors"][0]["code"])
	end

	it "should not update table object with properties with wrong type" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/-413",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				properties: "hello"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::PROPERTIES_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not update table object that does not exist" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/-413",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				properties: {}
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not update table object that belongs to another user" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/#{table_objects(:davSecondCard).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				properties: {}
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update table object with session that does not belong to the app" do
		jwt = generate_jwt(sessions(:davWebsiteSession))

		res = put_request(
			"/v1/table_object/#{table_objects(:davFirstCard).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				properties: {}
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not update table object that is a file" do
		jwt = generate_jwt(sessions(:sherlockTestAppSession))

		res = put_request(
			"/v1/table_object/#{table_objects(:sherlockTestFile).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
			{
				properties: {
					test1: "Hello World"
				}
			}
		)

		assert_response 422
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_IS_FILE, res["errors"][0]["code"])
	end

	it "should not update table object with too short property name" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = put_request(
			"/v1/table_object/#{table_objects(:mattSecondCard).id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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

	it "should update table object" do
		jwt = generate_jwt(sessions(:mattCardsSession))
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
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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

	it "should update table object with uuid" do
		jwt = generate_jwt(sessions(:mattCardsSession))
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
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		table_object = table_objects(:mattSecondCard)
		first_property_name = table_object_properties(:mattSecondCardPage1).name
		second_property_name = table_object_properties(:mattSecondCardPage2).name
		second_property_value = table_object_properties(:mattSecondCardPage2).value

		res = put_request(
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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

	it "should update table object and update last_active fields" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		table_object = table_objects(:mattSecondCard)

		res = put_request(
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt, 'Content-Type': 'application/json'},
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
	it "should not delete table object without jwt" do
		res = delete_request(
			"/v1/table_object/1"
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::JWT_MISSING, res["errors"][0]["code"])
	end

	it "should not delete table object with invalid jwt" do
		res = delete_request(
			"/v1/table_object/1",
			{Authorization: "asdasdasd.asdasd.sda"}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::SESSION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not delete table object that does not exist" do
		jwt = generate_jwt(sessions(:mattCardsSession))

		res = delete_request(
			"/v1/table_object/-413",
			{Authorization: jwt}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should delete table object" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		table_object = table_objects(:mattSecondCard)
		first_property = table_object_properties(:mattSecondCardPage1)
		second_property = table_object_properties(:mattSecondCardPage2)

		res = delete_request(
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt}
		)

		assert_response 204

		obj = TableObject.find_by(id: table_object.id)
		assert_nil(obj)

		prop1 = TableObjectProperty.find_by(id: first_property.id)
		assert_nil(prop1)
		
		prop2 = TableObjectProperty.find_by(id: second_property.id)
		assert_nil(prop2)
	end

	it "should delete table object with uuid" do
		jwt = generate_jwt(sessions(:mattCardsSession))
		table_object = table_objects(:mattSecondCard)
		first_property = table_object_properties(:mattSecondCardPage1)
		second_property = table_object_properties(:mattSecondCardPage2)

		res = delete_request(
			"/v1/table_object/#{table_object.uuid}",
			{Authorization: jwt}
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
		jwt = generate_jwt(sessions(:mattCardsSession))
		table_object = table_objects(:mattSecondCard)

		res = delete_request(
			"/v1/table_object/#{table_object.id}",
			{Authorization: jwt}
		)

		assert_response 204

		user = users(:matt)
		assert(Time.now.to_i - user.last_active.to_i < 10)

		app_user = app_users(:mattCards)
		assert(Time.now.to_i - app_user.last_active.to_i < 10)
	end

	it "should delete table object with file" do
		# TODO
	end
end