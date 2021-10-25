class CreateApiEndpointRequestCacheDependency < ActiveRecord::Migration[6.0]
  def change
    create_table :api_endpoint_request_cache_dependencies do |t|
		t.bigint :user_id
		t.bigint :table_id
		t.bigint :table_object_id
		t.bigint :collection_id
		t.bigint :api_endpoint_request_cache_id
		t.string :name
		t.timestamps
    end
  end
end
