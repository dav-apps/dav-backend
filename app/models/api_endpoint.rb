class ApiEndpoint < ApplicationRecord
	belongs_to :api_slot
	has_one :compiled_api_endpoint
end