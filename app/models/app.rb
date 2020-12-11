class App < ApplicationRecord
	belongs_to :dev
	has_many :tables, dependent: :destroy
	has_many :app_users, dependent: :destroy
	has_many :sessions, dependent: :destroy
end