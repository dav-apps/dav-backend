class CreateTableObjectPrice < ActiveRecord::Migration[6.0]
  def change
	 create_table :table_object_prices do |t|
		t.bigint :table_object_id
		t.integer :price, default: 0
		t.string :currency, default: "eur"
    end
  end
end
