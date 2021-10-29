class RemoveApiSlotIdFromCompiledApiEndpoint < ActiveRecord::Migration[6.0]
  def change
	remove_column :compiled_api_endpoints, :api_slot_id
  end
end
