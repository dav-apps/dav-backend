class CreateTableObject < ActiveRecord::Migration[6.0]
  def change
	 create_table :table_objects do |t|
		t.bigint :user_id
		t.bigint :table_id
		t.string :uuid
		t.boolean :file, default: false
		t.string :etag
		t.timestamps

		t.index :uuid, unique: true
    end
  end
end
