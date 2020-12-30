class CreateWebPushSubscription < ActiveRecord::Migration[6.0]
  def change
	 create_table :web_push_subscriptions do |t|
		t.bigint :session_id
		t.string :uuid
		t.index :uuid, unique: true
		t.string :endpoint
		t.string :p256dh
		t.string :auth
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
