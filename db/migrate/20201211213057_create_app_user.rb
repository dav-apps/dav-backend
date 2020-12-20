class CreateAppUser < ActiveRecord::Migration[6.0]
  def change
	 create_table :app_users do |t|
		t.bigint :user_id
		t.bigint :app_id
		t.bigint :used_storage, default: 0
		t.datetime :last_active
		t.timestamps
    end
  end
end
