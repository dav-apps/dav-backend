ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "./error_codes"
require_relative "../app/modules/constants"
require "rails/test_help"
require "minitest/rails"

class ActiveSupport::TestCase
	# Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
	fixtures :all

	# Helper methods
	def setup
		ENV["DAV_APPS_APP_ID"] = apps(:website).id.to_s

		# Set the table_alias of the TableObjectUserAccesses
		table_object_user_accesses(:mattAccessDavFirstCard).update_column(:table_alias, tables(:card).id)
		table_object_user_accesses(:mattAccessDavSecondCard).update_column(:table_alias, tables(:card).id)
	end

	def post_request(url, headers = {}, body = {})
		post url, headers: headers, params: body.to_json
		response.body.length > 0 ? JSON.parse(response.body) : nil
	end

	def get_request(url, headers = {}, json_response = true)
		get url, headers: headers
		json_response ? (response.body.length > 0 ? JSON.parse(response.body) : nil) : response.body
	end

	def put_request(url, headers = {}, body = {}, json = true)
		put url, headers: headers, params: json ? body.to_json : body
		response.body.length > 0 ? JSON.parse(response.body) : nil
	end

	def delete_request(url, headers = {})
		delete url, headers: headers
		response.body.length > 0 ? JSON.parse(response.body) : nil
	end

	def generate_auth(dev)
		dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
	end

	def generate_jwt(session)
		payload = {user_id: session.user.id, app_id: session.app.id, dev_id: session.app.dev.id, exp: session.exp.to_i}
		"#{JWT.encode(payload, session.secret, ENV['JWT_ALGORITHM'])}.#{session.id}"
	end

	def generate_table_object_etag(table_object)
		# uuid,property1Name:property1Value,property2Name:property2Value,...
		etag_string = table_object.uuid

		table_object.table_object_properties.each do |property|
			etag_string += ",#{property.name}:#{property.value}"
		end

		Digest::MD5.hexdigest(etag_string)
	end

	def get_total_storage(plan, confirmed)
		storage_unconfirmed = 1000000000 	# 1 GB
      storage_on_free_plan = 2000000000 	# 2 GB
      storage_on_plus_plan = 15000000000 	# 15 GB
      storage_on_pro_plan = 50000000000   # 50 GB

		if !confirmed
			return storage_unconfirmed
      elsif plan == 1	# User is on dav Plus
			return storage_on_plus_plan
		elsif plan == 2	# User is on dav Pro
			return storage_on_pro_plan
		else
			return storage_on_free_plan
		end
	end

	def upload_blob(table_object, blob)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		# Read the file
		contents = blob.class == StringIO ? blob.read : File.open(blob, "rb")

		client.create_block_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{table_object.table.app.id}/#{table_object.id}",
			contents
		)
	end

	def download_blob(table_object)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.get_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{table_object.table.app.id}/#{table_object.id}"
		)
	end
end
