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
		table_object_user_accesses(:klausAccessSnicketFirstBook).update_column(:table_alias, tables(:storeBook).id)
	end

	def post_request(url, headers = {}, body = {})
		post url, headers: headers, params: body.to_json
		response.body.length > 0 ? JSON.parse(response.body) : nil
	end

	def get_request(url, headers = {}, json_response = true)
		get url, headers: headers
		json_response ? (response.body.length > 0 ? JSON.parse(response.body) : nil) : response.body
	end

	def put_request(url, headers = {}, body = {})
		put url, headers: headers, params: body.is_a?(Hash) ? body.to_json : body
		response.body.length > 0 ? JSON.parse(response.body) : nil
	end

	def delete_request(url, headers = {})
		delete url, headers: headers
		response.body.length > 0 ? JSON.parse(response.body) : nil
	end

	def generate_auth(dev)
		dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
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

	def s3
		@s3 ||= Aws::S3::Client.new(
			access_key_id: ENV['SPACES_KEY'],
			secret_access_key: ENV['SPACES_SECRET'],
			endpoint: 'https://fra1.digitaloceanspaces.com',
			region: 'us-east-1'
		)
	end

	def upload_blob(table_object, blob, content_type)
		# Read the file
		contents = blob.class == StringIO ? blob.string : File.open(blob, "rb").read

		s3.put_object({
			bucket: ENV["SPACE_NAME"],
			key: table_object.uuid,
			body: contents,
			acl: table_object.table.cdn ? "public-read" : "private",
			content_type: content_type
		})
	end

	def download_blob(table_object)
		tempfile = Tempfile.new

		result = s3.get_object(
			bucket: ENV["SPACE_NAME"],
			key: table_object.uuid,
			response_target: tempfile.path
		)

		return result, File.open(tempfile.path, "rb").read
	end

	def upload_profile_image(user, blob, content_type)
		# Read the file
		contents = blob.class == StringIO ? blob.string : File.open(blob, "rb").read

		UtilsService.s3.put_object({
			bucket: ENV["SPACE_NAME"],
			key: "profileImages/#{user.id}",
			body: contents,
			acl: "public-read",
			content_type: content_type
		})
	end
end
