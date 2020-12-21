ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "./error_codes"
require_relative "../app/modules/constants"
require "rails/test_help"
require "minitest/rails"

class ActiveSupport::TestCase
	# Run tests in parallel with specified workers
	parallelize(workers: :number_of_processors)

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
		JSON.parse(response.body)
	end

	def get_request(url, headers = {})
		get url, headers: headers
		JSON.parse(response.body)
	end

	def delete_request(url, headers = {})
		delete url, headers: headers
		response.body.length < 2 ? nil : JSON.parse(response.body)
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
end
