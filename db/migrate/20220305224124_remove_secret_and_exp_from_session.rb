class RemoveSecretAndExpFromSession < ActiveRecord::Migration[6.1]
  def change
	remove_column :sessions, :secret
	remove_column :sessions, :exp
  end
end
