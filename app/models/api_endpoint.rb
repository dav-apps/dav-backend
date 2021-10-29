class ApiEndpoint < ApplicationRecord
	belongs_to :api_slot
	has_many :compiled_api_endpoints
	has_many :api_endpoint_request_caches, dependent: :destroy, class_name: "ApiEndpointRequestCache"
end