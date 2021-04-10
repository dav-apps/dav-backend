class TableObjectPurchase < ApplicationRecord
	belongs_to :table_object
	belongs_to :purchase
end