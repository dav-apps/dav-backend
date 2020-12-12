class CreateApi < ActiveRecord::Migration[6.0]
  def change
	 create_table :apis do |t|
		t.bigint :app_id
		t.string :name
		t.timestamps
    end
  end
end
