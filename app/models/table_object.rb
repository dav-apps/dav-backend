class TableObject < ApplicationRecord
	belongs_to :table
	belongs_to :user
	has_many :table_object_properties, dependent: :destroy
	has_many :table_object_collections, dependent: :destroy
	has_many :table_object_user_access, dependent: :destroy
	has_many :purchases, dependent: :destroy

	validates :uuid, presence: true, uniqueness: { case_sensitive: false }
end