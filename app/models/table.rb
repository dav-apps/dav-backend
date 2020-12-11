class Table < ApplicationRecord
	belongs_to :app
	has_many :table_objects, dependent: :destroy
	has_many :table_property_types, dependent: :destroy
	has_many :collections, dependent: :destroy
end