class RenameApiIdOfApiEndpointToApiSlotId < ActiveRecord::Migration[6.0]
  def change
	rename_column :api_endpoints, :api_id, :api_slot_id
  end
end
