class Api < ApplicationRecord
	belongs_to :app
	has_many :api_endpoints, dependent: :destroy
end