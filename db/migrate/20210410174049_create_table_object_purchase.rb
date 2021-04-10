class CreateTableObjectPurchase < ActiveRecord::Migration[6.0]
  def change
    create_table :table_object_purchases do |t|
		t.bigint :table_object_id
		t.bigint :purchase_id
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
