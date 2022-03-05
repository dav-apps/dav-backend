class DropTableObjectChanges < ActiveRecord::Migration[6.1]
  def change
	drop_table :table_object_changes
  end
end
