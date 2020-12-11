class CreateDev < ActiveRecord::Migration[6.0]
  def change
	 create_table :devs do |t|
		t.bigint :user_id
		t.string :api_key
		t.string :secret_key
		t.string :uuid
		t.datetime :created_at, null: false
    end
  end
end
