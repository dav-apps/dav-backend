require "test_helper"

describe ApiEnvVarsController do
	setup do
		setup
	end

	# set_api_env_vars
	it "should not set api env vars without auth" do
		res = put_request("/v1/api/1/env_vars")

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTH_HEADER_MISSING, res["errors"][0]["code"])
	end

	it "should not set api env vars without Content-Type json" do
		res = put_request(
			"/v1/api/1/env_vars",
			{Authorization: "asasassadsda"}
		)

		assert_response 415
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED, res["errors"][0]["code"])
	end

	it "should not set api env vars with invalid auth" do
		res = put_request(
			"/v1/api/1/env_vars",
			{Authorization: "#{devs(:dav).api_key},jhdfhasd9", 'Content-Type': 'application/json'}
		)

		assert_response 401
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::AUTHENTICATION_FAILED, res["errors"][0]["code"])
	end

	it "should not set api env vars without required properties" do
		res = put_request(
			"/v1/api/1/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VARS_MISSING, res["errors"][0]["code"])
	end

	it "should not set api env vars with wrong types" do
		res = put_request(
			"/v1/api/1/env_vars",
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
			"/v1/api/1/env_vars",
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

	it "should not set api env vars with too short properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/env_vars",
			{Authorization: generate_auth(devs(:dav)), 'Content-Type': 'application/json'},
			{
				env_vars: {
					test: "a"
				}
			}
		)

		assert_response 400
		assert_equal(1, res["errors"].length)
		assert_equal(ErrorCodes::ENV_VAR_VALUE_TOO_SHORT, res["errors"][0]["code"])
	end

	it "should not set api env vars with too long properties" do
		api = apis(:pocketlibApi)

		res = put_request(
			"/v1/api/#{api.id}/env_vars",
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
			"/v1/api/#{api.id}/env_vars",
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

	it "should create new api env vars in set api env vars" do
		api = apis(:pocketlibApi)
		env_vars_count = api.api_env_vars.count
		first_env_var_name = "test1"
		first_env_var_value = "Hello World"
		second_env_var_name = "test2"
		second_env_var_value = 1234
		third_env_var_name = "test3"
		third_env_var_value = 42.14
		fourth_env_var_name = "test4"
		fourth_env_var_value = [1, 2, 3, 4]

		res = put_request(
			"/v1/api/#{api.id}/env_vars",
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
		assert_equal(env_vars_count + 4, api.api_env_vars.count)

		first_env_var = ApiEnvVar.find_by(api: api, name: first_env_var_name)
		assert_not_nil(first_env_var)
		assert_equal(api.id, first_env_var.api_id)
		assert_equal(first_env_var_name, first_env_var.name)
		assert_equal(first_env_var_value, first_env_var.value)
		assert_equal("string", first_env_var.class_name)

		second_env_var = ApiEnvVar.find_by(api: api, name: second_env_var_name)
		assert_not_nil(second_env_var)
		assert_equal(api.id, second_env_var.api_id)
		assert_equal(second_env_var_name, second_env_var.name)
		assert_equal(second_env_var_value.to_s, second_env_var.value)
		assert_equal("int", second_env_var.class_name)

		third_env_var = ApiEnvVar.find_by(api: api, name: third_env_var_name)
		assert_not_nil(third_env_var)
		assert_equal(api.id, third_env_var.api_id)
		assert_equal(third_env_var_name, third_env_var.name)
		assert_equal(third_env_var_value.to_s, third_env_var.value)
		assert_equal("float", third_env_var.class_name)

		fourth_env_var = ApiEnvVar.find_by(api: api, name: fourth_env_var_name)
		assert_not_nil(fourth_env_var)
		assert_equal(api.id, fourth_env_var.api_id)
		assert_equal(fourth_env_var_name, fourth_env_var.name)
		assert_equal(fourth_env_var_value.join(','), fourth_env_var.value)
		assert_equal("array:int", fourth_env_var.class_name)
	end

	it "should update existing api env vars in set api env vars" do
		api = apis(:pocketlibApi)
		env_vars_count = api.api_env_vars.count
		first_env_var = api_env_vars(:pocketlibApiFirstEnvVar)
		first_env_var_value = 523
		second_env_var = api_env_vars(:pocketlibApiSecondEnvVar)
		second_env_var_value = ["asd", "3fs", "osd93", "asdaaaaa2"]
		third_env_var = api_env_vars(:pocketlibApiThirdEnvVar)
		third_env_var_value = "Updated value"
		fourth_env_var = api_env_vars(:pocketlibApiFourthEnvVar)
		fourth_env_var_value = 63.423

		res = put_request(
			"/v1/api/#{api.id}/env_vars",
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
		assert_equal(env_vars_count, api.api_env_vars.count)

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