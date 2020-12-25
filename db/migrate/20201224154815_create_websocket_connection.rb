class CreateWebsocketConnection < ActiveRecord::Migration[6.0]
  def change
	 create_table :websocket_connections do |t|
		t.bigint :user_id
		t.bigint :app_id
		t.string :token, null: false
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
