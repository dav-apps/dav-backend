class AddDocumentationToApiSlot < ActiveRecord::Migration[6.1]
  def change
    add_column :api_slots, :documentation, :text
  end
end
