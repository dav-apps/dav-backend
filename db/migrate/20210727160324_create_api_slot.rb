class CreateApiSlot < ActiveRecord::Migration[6.0]
  def change
    create_table :api_slots do |t|
		t.bigint :api_id
		t.string :name
		t.timestamps
    end
  end
end
