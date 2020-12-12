class CreateApiEndpoint < ActiveRecord::Migration[6.0]
  def change
	 create_table :api_endpoints do |t|
		t.bigint :api_id
		t.string :path
		t.string :method
		t.text :commands
		t.boolean :caching, default: false
		t.timestamps
    end
  end
end
