class DropApiEndpointRequestCaches < ActiveRecord::Migration[6.1]
  def change
	drop_table :api_endpoint_request_caches
  end
end
