class CreateCompiledApiEndpoint < ActiveRecord::Migration[6.0]
  def change
    create_table :compiled_api_endpoints do |t|
		t.bigint :api_slot_id
		t.bigint :api_endpoint_id
		t.text :code
		t.timestamps
    end
  end
end
