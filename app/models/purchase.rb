class Purchase < ApplicationRecord
	belongs_to :user
	has_many :table_object_purchases, dependent: :destroy
	has_many :table_objects, through: :table_object_purchases
end