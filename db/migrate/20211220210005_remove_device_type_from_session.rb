class RemoveDeviceTypeFromSession < ActiveRecord::Migration[6.0]
  def change
	remove_column :sessions, :device_type
  end
end
