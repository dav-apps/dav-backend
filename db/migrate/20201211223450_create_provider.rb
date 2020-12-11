class CreateProvider < ActiveRecord::Migration[6.0]
  def change
	 create_table :providers do |t|
		t.bigint :user_id
		t.string :stripe_account_id
		t.timestamps
    end
  end
end
