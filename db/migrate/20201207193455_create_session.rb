class CreateSession < ActiveRecord::Migration[6.0]
  def change
	 create_table :sessions do |t|
		t.bigint :user_id
		t.bigint :app_id
		t.string :token
		t.string :old_token
		t.string :device_name
		t.string :device_type
		t.string :device_os
		t.timestamps

		t.index :token, unique: true
		t.index :old_token, unique: true
    end
  end
end
