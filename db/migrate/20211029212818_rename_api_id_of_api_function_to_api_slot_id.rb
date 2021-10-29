class RenameApiIdOfApiFunctionToApiSlotId < ActiveRecord::Migration[6.0]
  def change
	rename_column :api_functions, :api_id, :api_slot_id
  end
end
