class Dev < ApplicationRecord
	belongs_to :user
	has_many :apps, dependent: :destroy
end