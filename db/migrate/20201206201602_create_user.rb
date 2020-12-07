class CreateUser < ActiveRecord::Migration[6.0]
  def change
	 create_table :users do |t|
		t.string :email
		t.string :first_name
		t.string :password_digest
		t.boolean :confirmed, default: false
		t.string :email_confirmation_token
		t.string :password_confirmation_token
		t.string :old_email
		t.string :new_email
		t.string :new_password
		t.bigint :used_storage, default: 0
		t.datetime :last_active
		t.string :stripe_customer_id
		t.integer :plan, default: 0
		t.integer :subscription_status, default: 0
		t.timestamp :period_end
		t.timestamps
    end
  end
end
