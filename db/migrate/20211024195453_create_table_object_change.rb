class CreateTableObjectChange < ActiveRecord::Migration[6.0]
  def change
    create_table :table_object_changes do |t|
		t.bigint :table_id
		t.bigint :table_object_id
		t.integer :change
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
