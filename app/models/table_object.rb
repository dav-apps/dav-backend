class TableObject < ApplicationRecord
	belongs_to :table
	belongs_to :user
	has_many :table_object_properties, dependent: :destroy

	validates :uuid, presence: true, uniqueness: true
end