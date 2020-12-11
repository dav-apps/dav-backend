class CreateAppUserActivity < ActiveRecord::Migration[6.0]
  def change
	 create_table :app_user_activities do |t|
		t.bigint :app_id
		t.datetime :time
		t.integer :count_daily, default: 0
		t.integer :count_monthly, default: 0
		t.integer :count_yearly, default: 0
    end
  end
end
