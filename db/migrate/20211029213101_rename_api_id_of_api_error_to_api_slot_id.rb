class RenameApiIdOfApiErrorToApiSlotId < ActiveRecord::Migration[6.0]
  def change
	rename_column :api_errors, :api_id, :api_slot_id
  end
end
