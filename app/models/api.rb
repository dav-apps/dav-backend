class Api < ApplicationRecord
	belongs_to :app
	has_many :api_slots, dependent: :destroy
end