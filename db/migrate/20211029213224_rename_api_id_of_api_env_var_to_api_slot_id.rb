class RenameApiIdOfApiEnvVarToApiSlotId < ActiveRecord::Migration[6.0]
  def change
	rename_column :api_env_vars, :api_id, :api_slot_id
  end
end
