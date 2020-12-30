class Session < ApplicationRecord
	belongs_to :user
	belongs_to :app

	has_many :web_push_subscriptions, dependent: :destroy
end