class TableEtag < ApplicationRecord
	belongs_to :user
	belongs_to :table
end