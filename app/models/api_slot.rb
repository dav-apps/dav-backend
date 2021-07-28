class ApiSlot < ApplicationRecord
	belongs_to :api
	has_many :compiled_api_endpoints, dependent: :destroy
end