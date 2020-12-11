class CreateNotificationProperty < ActiveRecord::Migration[6.0]
  def change
	 create_table :notification_properties do |t|
		t.bigint :notification_id
		t.string :name
		t.text :value
    end
  end
end
