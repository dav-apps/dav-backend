class CreateNotification < ActiveRecord::Migration[6.0]
  def change
	 create_table :notifications do |t|
		t.bigint :user_id
		t.bigint :app_id
		t.string :uuid
		t.index :uuid, unique: true
		t.datetime :time
		t.integer :interval
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
