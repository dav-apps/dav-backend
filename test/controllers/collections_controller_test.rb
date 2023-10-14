require "test_helper"

describe CollectionsController do
	setup do
		setup
	end

	# set_table_objects_of_collection
	it "should not set table objects without auth" do
		res = put_request("/v1/collection/table_objects")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set table objects without Content-Type json" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: "asdasdsad"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set table objects with dev that does not exist" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: "asdasdasd,13wdfio23r8hifwe", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set table objects with invalid auth" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not set table objects without required properties" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_MISSING, res["errors"][0]["code"])
		assert_equal(ErrorCodes::NAME_MISSING, res["errors"][1]["code"])
		assert_equal(ErrorCodes::TABLE_OBJECTS_MISSING, res["errors"][2]["code"])
	end

	it "should not set table objects with properties with wrong types" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				table_id: "test",
				name: 112,
				table_objects: [1, 2, 3]
			}
		)

		assert_response 400
		assert_equal(3, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_WRONG_TYPE, res["errors"][0]["code"])
		assert_equal(ErrorCodes::NAME_WRONG_TYPE, res["errors"][1]["code"])
		assert_equal(ErrorCodes::TABLE_OBJECTS_WRONG_TYPE, res["errors"][2]["code"])
	end

	it "should not set table objects for table that does not exist" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				table_id: -123,
				name: "test",
				table_objects: []
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set table objects with another dev" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				table_id: tables(:storeBook).id,
				name: "latest_books",
				table_objects: []
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not set table objects of collection that does not exist" do
		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				table_id: tables(:storeBook).id,
				name: "test",
				table_objects: []
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::COLLECTION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set table objects that do not exist" do
		collection = collections(:latest_books_collection)

		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				table_id: collection.table_id,
				name: collection.name,
				table_objects: [
					"sdfjsdfjsdfd",
					"oshdgisghsofdj"
				]
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not set table objects that belong to the table of another app" do
		collection = collections(:latest_books_collection)

		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				table_id: collection.table_id,
				name: collection.name,
				table_objects: [
					table_objects(:mattFirstCard).uuid,
					table_objects(:mattSecondCard).uuid
				]
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should set table objects" do
		collection = collections(:latest_books_collection)

		res = put_request(
			"/v1/collection/table_objects",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				table_id: collection.table_id,
				name: collection.name,
				table_objects: [
					table_objects(:snicketFirstBook).uuid,
					table_objects(:snicketSecondBook).uuid,
					table_objects(:hindenburgFirstBook).uuid
				]
			}
		)

		assert_response 200
		assert_equal(collection.id, res["id"])
		assert_equal(collection.table_id, res["table_id"])
		assert_equal(collection.name, res["name"])

		# Get the TableObjectCollections
		assert_equal(3, collection.table_object_collections.length)
		assert_equal(table_objects(:snicketFirstBook).uuid, collection.table_object_collections[0].table_object.uuid)
		assert_equal(table_objects(:snicketSecondBook).uuid, collection.table_object_collections[1].table_object.uuid)
		assert_equal(table_objects(:hindenburgFirstBook).uuid, collection.table_object_collections[2].table_object.uuid)
	end

	# add_table_object_to_collection
	it "should not add table object to collection without auth" do
		res = post_request("/v2/collections/asd/table_objects/asdasdasd")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not add table object to collection without Content-Type json" do
		res = post_request(
			"/v2/collections/asd/table_objects/asdasdasd",
			{Authorization: "kjsdhakjsd"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not add table object to collection with dev that does not exist" do
		res = post_request(
			"/v2/collections/asd/table_objects/asdasdasd",
			{Authorization: "asdasdasd,13wdfio23r8hifwe", 'Content-Type': 'application/json'}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::DEV_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not add table object to collection with invalid auth" do
		res = post_request(
			"/v2/collections/asd/table_objects/asdasdasd",
			{Authorization: "v05Bmn5pJT_pZu6plPQQf8qs4ahnK3cv2tkEK5XJ,13wdfio23r8hifwe", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not add table object to collection without required properties" do
		res = post_request(
			"/v2/collections/asd/table_objects/asdasdasd",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_MISSING, res["errors"][0]["code"])
	end

	it "should not add table object to collection with properties with wrong types" do
		res = post_request(
			"/v2/collections/asd/table_objects/asdasdasd",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{table_id: "soos"}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_ID_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not add table object to collection with table that does not exist" do
		res = post_request(
			"/v2/collections/asd/table_objects/asdasdasd",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{table_id: -12}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not add table object to collection with table that does not belong to the dev" do
		collection = collections(:latest_books_collection)
		table = tables(:note)

		res = post_request(
			"/v2/collections/#{collection.name}/table_objects/asdasdasd",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{table_id: table.id}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not add table object to collection with collection that does not exist" do
		table = tables(:storeBook)

		res = post_request(
			"/v2/collections/asdasdads/table_objects/asdasdasd",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{table_id: table.id}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::COLLECTION_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should not add table object to collection with table object that does not exist" do
		collection = collections(:latest_books_collection)
		table = tables(:storeBook)

		res = post_request(
			"/v2/collections/#{collection.name}/table_objects/asdasdasd",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{table_id: table.id}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::TABLE_OBJECT_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should add table object to collection" do
		collection = collections(:latest_books_collection)
		table = tables(:storeBook)
		table_object = table_objects(:hindenburgFirstBook)

		res = post_request(
			"/v2/collections/#{collection.name}/table_objects/#{table_object.uuid}",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{table_id: table.id}
		)

		assert_response 200
		assert_equal(collection.id, res["id"])
		assert_equal(collection.table_id, table.id)
		assert_equal(collection.name, res["name"])
	end
end
