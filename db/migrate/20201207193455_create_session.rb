class CreateSession < ActiveRecord::Migration[6.0]
  def change
	 create_table :sessions do |t|
		t.bigint :user_id
		t.bigint :app_id
		t.string :secret
		t.datetime :exp
		t.string :device_name
		t.string :device_type
		t.string :device_os
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
