class CompiledApiEndpoint < ApplicationRecord
	belongs_to :api_slot
	belongs_to :api_endpoint
end