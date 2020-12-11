class CreateTableObjectUserAccess < ActiveRecord::Migration[6.0]
  def change
	 create_table :table_object_user_accesses do |t|
		t.bigint :user_id
		t.bigint :table_object_id
		t.bigint :table_alias
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
