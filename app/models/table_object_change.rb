class TableObjectChange < ApplicationRecord
	belongs_to :table
	belongs_to :table_object
end