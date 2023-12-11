class AddIgnoreFileSizeToTable < ActiveRecord::Migration[7.0]
  def change
    add_column :tables, :ignore_file_size, :boolean, default: false
  end
end
