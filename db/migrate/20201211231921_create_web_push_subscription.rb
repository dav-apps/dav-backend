class CreateWebPushSubscription < ActiveRecord::Migration[6.0]
  def change
	 create_table :web_push_subscriptions do |t|
		t.bigint :user_id
		t.string :uuid
		t.string :endpoint
		t.string :p256dh
		t.string :auth
    end
  end
end
