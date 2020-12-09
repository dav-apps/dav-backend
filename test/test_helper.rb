ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "./error_code"
require "rails/test_help"
require "minitest/rails"

# Consider setting MT_NO_EXPECTATIONS to not add expectations to Object.
# ENV["MT_NO_EXPECTATIONS"] = true

class ActiveSupport::TestCase
	# Run tests in parallel with specified workers
	parallelize(workers: :number_of_processors)

	# Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
	fixtures :all

	# Helper methods
	def post_request(url, headers = {}, body = {})
		post url, headers: headers, params: body.to_json
		JSON.parse(response.body)
	end

	def generate_auth(dev)
		dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
	end
end
