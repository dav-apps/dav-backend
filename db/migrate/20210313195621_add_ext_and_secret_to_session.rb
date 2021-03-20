class AddExtAndSecretToSession < ActiveRecord::Migration[6.0]
  def change
	add_column :sessions, :secret, :string
	add_column :sessions, :exp, :datetime
  end
end