class AddUuidToPurchase < ActiveRecord::Migration[6.0]
  def change
	add_column :purchases, :uuid, :string
	add_index :purchases, :uuid, unique: true
  end
end
