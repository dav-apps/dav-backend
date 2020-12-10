ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "./error_codes"
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
	end

	def post_request(url, headers = {}, body = {})
		post url, headers: headers, params: body.to_json
		JSON.parse(response.body)
	end

	def generate_auth(dev)
		dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
	end
end

module Constants
	MATT_PASSWORD = "schachmatt"
end