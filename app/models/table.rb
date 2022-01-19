class Table < ApplicationRecord
	belongs_to :app
	has_many :table_etags, dependent: :destroy
	has_many :table_objects, dependent: :destroy
	has_many :table_property_types, dependent: :destroy
	has_many :collections, dependent: :destroy
	has_many :table_object_changes
	has_many :api_endpoint_request_cache_dependencies
end