class CreateApiFunction < ActiveRecord::Migration[6.0]
  def change
	 create_table :api_functions do |t|
		t.bigint :api_id
		t.string :name
		t.string :params
		t.text :commands
		t.timestamps
    end
  end
end
