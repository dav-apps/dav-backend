class CreateSession < ActiveRecord::Migration[6.0]
  def change
	 create_table :sessions do |t|
		t.integer :user_id
		t.integer :app_id
		t.string :secret
		t.datetime :exp
		t.string :device_name
		t.string :device_type
		t.string :device_os
		t.datetime :created_at, null: false
    end
  end
end
