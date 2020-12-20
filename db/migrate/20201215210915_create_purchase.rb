class CreatePurchase < ActiveRecord::Migration[6.0]
  def change
	 create_table :purchases do |t|
		t.bigint :user_id
		t.bigint :table_object_id
		t.string :payment_intent_id
		t.string :provider_name
		t.string :provider_image
		t.string :product_name
		t.string :product_image
		t.integer :price
		t.string :currency
		t.boolean :completed, default: false
		t.timestamps
    end
  end
end
