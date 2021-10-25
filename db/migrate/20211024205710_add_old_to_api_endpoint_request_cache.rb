class AddOldToApiEndpointRequestCache < ActiveRecord::Migration[6.0]
  def change
	add_column :api_endpoint_request_caches, :old, :boolean, default: true
  end
end
