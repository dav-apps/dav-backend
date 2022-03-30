class AddCdnToTable < ActiveRecord::Migration[6.1]
  def change
	add_column :tables, :cdn, :boolean, default: false
  end
end
