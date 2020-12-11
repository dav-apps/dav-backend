class CreateTableObjectCollection < ActiveRecord::Migration[6.0]
  def change
	 create_table :table_object_collections do |t|
		t.bigint :table_object_id
		t.bigint :collection_id
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
