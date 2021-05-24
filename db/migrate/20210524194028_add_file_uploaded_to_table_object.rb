class AddFileUploadedToTableObject < ActiveRecord::Migration[6.0]
  def change
    add_column :table_objects, :file_uploaded, :boolean, default: false
  end
end
