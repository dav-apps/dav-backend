class App < ApplicationRecord
	belongs_to :dev
	has_many :tables, dependent: :destroy
end