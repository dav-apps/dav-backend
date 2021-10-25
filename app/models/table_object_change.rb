class TableObjectChange < ApplicationRecord
	belongs_to :user, optional: true
	belongs_to :table, optional: true
	belongs_to :table_object, optional: true
	belongs_to :collection, optional: true
end