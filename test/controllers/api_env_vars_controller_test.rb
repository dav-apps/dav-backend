require "test_helper"

describe ApiEnvVarsController do
	setup do
		setup
	end

	# set_api_env_vars
	it "should not set api env vars without auth" do
		res = put_request("/v1/api/1/master/env_vars")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set api env vars without Content-Type json" do
		res = put_request(
			"/v1/api/1/master/env_vars",
			{Authorization: "asasassadsda"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set api env vars with invalid auth" do
		res = put_request(
			"/v1/api/1/master/env_vars",
			{Authorization: "#{devs(:dav).api_key},jhdfhasd9", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not set api env vars without required properties" do
		res = put_request(
			"/v1/api/1/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VARS_MISSING, res["errors"][0]["code"])
	end

	it "should not set api env vars with wrong types" do
		res = put_request(
			"/v1/api/1/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: "Hello World"
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VARS_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not set api env vars with env vars with wrong types" do
		res = put_request(
			"/v1/api/1/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					test: {test: "test"}
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VAR_VALUE_WRONG_TYPE, res["errors"][0]["code"])
	end

	it "should not set api env vars with too short property name" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					"": "Hello"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VAR_NAME_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not set api env vars with too long property name" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					"#{'a' * 200}": "Hello"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VAR_NAME_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not set api env vars with too short property value" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					test: ""
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VAR_VALUE_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not set api env vars with too long property value" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					test: "a" * 300
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VAR_VALUE_TOO_LONG, res["errors"][0]["code"])
	end

	it "should not set api env vars for api of the app of another dev" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/master/env_vars",
			{Authorization: generate_auth(devs(:sherlock)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					"test": "Hello World"
				}
			}
		)

		assert_response 403
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ACTION_NOT_ALLOWED, res["errors"][0]["code"])
	end

	it "should not set api env vars for api that does not exist" do
		res = put_request(
			"/v1/api/-123/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					"test": "Hello World"
				}
			}
		)

		assert_response 404
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::API_DOES_NOT_EXIST, res["errors"][0]["code"])
	end

	it "should create new api env vars in set api env vars" do
		api = apis(:pocketlibApi)
		api_slot = api_slots(:pocketlibApiMaster)
		env_vars_count = api_slot.api_env_vars.count
		first_env_var_name = "test1"
		first_env_var_value = "Hello World"
		second_env_var_name = "test2"
		second_env_var_value = 1234
		third_env_var_name = "test3"
		third_env_var_value = 42.14
		fourth_env_var_name = "test4"
		fourth_env_var_value = [1, 2, 3, 4]

		res = put_request(
			"/v1/api/#{api.id}/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					"#{first_env_var_name}": first_env_var_value,
					"#{second_env_var_name}": second_env_var_value,
					"#{third_env_var_name}": third_env_var_value,
					"#{fourth_env_var_name}": fourth_env_var_value
				}
			}
		)

		assert_response 204
		assert_equal(env_vars_count + 4, api_slot.api_env_vars.count)

		first_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: first_env_var_name)
		assert_not_nil(first_env_var)
		assert_equal(api_slot.id, first_env_var.api_slot_id)
		assert_equal(first_env_var_name, first_env_var.name)
		assert_equal(first_env_var_value, first_env_var.value)
		assert_equal("string", first_env_var.class_name)

		second_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: second_env_var_name)
		assert_not_nil(second_env_var)
		assert_equal(api_slot.id, second_env_var.api_slot_id)
		assert_equal(second_env_var_name, second_env_var.name)
		assert_equal(second_env_var_value.to_s, second_env_var.value)
		assert_equal("int", second_env_var.class_name)

		third_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: third_env_var_name)
		assert_not_nil(third_env_var)
		assert_equal(api_slot.id, third_env_var.api_slot_id)
		assert_equal(third_env_var_name, third_env_var.name)
		assert_equal(third_env_var_value.to_s, third_env_var.value)
		assert_equal("float", third_env_var.class_name)

		fourth_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: fourth_env_var_name)
		assert_not_nil(fourth_env_var)
		assert_equal(api_slot.id, fourth_env_var.api_slot_id)
		assert_equal(fourth_env_var_name, fourth_env_var.name)
		assert_equal(fourth_env_var_value.join(','), fourth_env_var.value)
		assert_equal("array:int", fourth_env_var.class_name)
	end

	it "should create new api env vars and create new api slot in set api env vars" do
		api = apis(:pocketlibApi)
		api_slot_name = "testslot"
		first_env_var_name = "test1"
		first_env_var_value = "Hello World"
		second_env_var_name = "test2"
		second_env_var_value = 1234
		third_env_var_name = "test3"
		third_env_var_value = 42.14
		fourth_env_var_name = "test4"
		fourth_env_var_value = [1, 2, 3, 4]

		res = put_request(
			"/v1/api/#{api.id}/#{api_slot_name}/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					"#{first_env_var_name}": first_env_var_value,
					"#{second_env_var_name}": second_env_var_value,
					"#{third_env_var_name}": third_env_var_value,
					"#{fourth_env_var_name}": fourth_env_var_value
				}
			}
		)

		assert_response 204

		api_slot = ApiSlot.find_by(api: api, name: api_slot_name)
		assert_not_nil(api_slot)
		assert_equal(api_slot.name, api_slot_name)
		assert_equal(4, api_slot.api_env_vars.count)

		first_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: first_env_var_name)
		assert_not_nil(first_env_var)
		assert_equal(api_slot.id, first_env_var.api_slot_id)
		assert_equal(first_env_var_name, first_env_var.name)
		assert_equal(first_env_var_value, first_env_var.value)
		assert_equal("string", first_env_var.class_name)

		second_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: second_env_var_name)
		assert_not_nil(second_env_var)
		assert_equal(api_slot.id, second_env_var.api_slot_id)
		assert_equal(second_env_var_name, second_env_var.name)
		assert_equal(second_env_var_value.to_s, second_env_var.value)
		assert_equal("int", second_env_var.class_name)

		third_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: third_env_var_name)
		assert_not_nil(third_env_var)
		assert_equal(api_slot.id, third_env_var.api_slot_id)
		assert_equal(third_env_var_name, third_env_var.name)
		assert_equal(third_env_var_value.to_s, third_env_var.value)
		assert_equal("float", third_env_var.class_name)

		fourth_env_var = ApiEnvVar.find_by(api_slot: api_slot, name: fourth_env_var_name)
		assert_not_nil(fourth_env_var)
		assert_equal(api_slot.id, fourth_env_var.api_slot_id)
		assert_equal(fourth_env_var_name, fourth_env_var.name)
		assert_equal(fourth_env_var_value.join(','), fourth_env_var.value)
		assert_equal("array:int", fourth_env_var.class_name)
	end

	it "should update existing api env vars in set api env vars" do
		api = apis(:pocketlibApi)
		api_slot = api_slots(:pocketlibApiMaster)
		env_vars_count = api_slot.api_env_vars.count
		first_env_var = api_env_vars(:pocketlibApiFirstEnvVar)
		first_env_var_value = 523
		second_env_var = api_env_vars(:pocketlibApiSecondEnvVar)
		second_env_var_value = ["asd", "3fs", "osd93", "asdaaaaa2"]
		third_env_var = api_env_vars(:pocketlibApiThirdEnvVar)
		third_env_var_value = "Updated value"
		fourth_env_var = api_env_vars(:pocketlibApiFourthEnvVar)
		fourth_env_var_value = 63.423

		res = put_request(
			"/v1/api/#{api.id}/master/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					"#{first_env_var.name}": first_env_var_value,
					"#{second_env_var.name}": second_env_var_value,
					"#{third_env_var.name}": third_env_var_value,
					"#{fourth_env_var.name}": fourth_env_var_value
				}
			}
		)

		assert_response 204
		assert_equal(env_vars_count, api_slot.api_env_vars.count)

		first_env_var = ApiEnvVar.find_by(id: first_env_var.id)
		assert_not_nil(first_env_var)
		assert_equal(first_env_var_value.to_s, first_env_var.value)
		assert_equal("int", first_env_var.class_name)

		second_env_var = ApiEnvVar.find_by(id: second_env_var.id)
		assert_not_nil(second_env_var)
		assert_equal(second_env_var_value.join(','), second_env_var.value)
		assert_equal("array:string", second_env_var.class_name)

		third_env_var = ApiEnvVar.find_by(id: third_env_var.id)
		assert_not_nil(third_env_var)
		assert_equal(third_env_var_value, third_env_var.value)
		assert_equal("string", third_env_var.class_name)

		fourth_env_var = ApiEnvVar.find_by(id: fourth_env_var.id)
		assert_not_nil(fourth_env_var)
		assert_equal(fourth_env_var_value.to_s, fourth_env_var.value)
		assert_equal("float", fourth_env_var.class_name)
	end
end