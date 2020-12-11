class CreateTableObject < ActiveRecord::Migration[6.0]
  def change
	 create_table :table_objects do |t|
		t.bigint :user_id
		t.bigint :table_id
		t.string :uuid
		t.index :uuid, unique: true
		t.boolean :file, default: false
		t.timestamps
    end
  end
end
