class CreateApiEndpointRequestCache < ActiveRecord::Migration[6.0]
  def change
	 create_table :api_endpoint_request_caches do |t|
		t.bigint :api_endpoint_id
		t.text :response
		t.timestamps
    end
  end
end
