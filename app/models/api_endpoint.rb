class ApiEndpoint < ApplicationRecord
	belongs_to :api_slot
	has_one :compiled_api_endpoint
	has_many :api_endpoint_request_caches, dependent: :destroy, class_name: "ApiEndpointRequestCache"
end