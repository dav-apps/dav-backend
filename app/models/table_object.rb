class TableObject < ApplicationRecord
	belongs_to :table
	belongs_to :user
	has_many :table_object_properties, dependent: :destroy
	has_many :table_object_prices, dependent: :destroy
	has_many :table_object_user_access, dependent: :destroy
	has_many :table_object_collections, dependent: :destroy
	has_many :collections, through: :table_object_collections
	has_many :table_object_purchases, dependent: :destroy
	has_many :purchases, through: :table_object_purchases
	has_many :table_object_changes

	validates :uuid, presence: true, uniqueness: { case_sensitive: false }
end