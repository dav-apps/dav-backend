class RemoveTableObjectIdFromPurchase < ActiveRecord::Migration[6.0]
  def change
	remove_column :purchases, :table_object_id, :bigint
  end
end
