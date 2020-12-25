class App < ApplicationRecord
	belongs_to :dev
	has_many :tables, dependent: :destroy
	has_many :app_users, dependent: :destroy
	has_many :sessions, dependent: :destroy
	has_many :app_user_activities, dependent: :destroy
	has_many :exception_events, dependent: :destroy
	has_many :notifications, dependent: :destroy
	has_many :apis, dependent: :destroy
	has_many :websocket_connections, dependent: :destroy
end