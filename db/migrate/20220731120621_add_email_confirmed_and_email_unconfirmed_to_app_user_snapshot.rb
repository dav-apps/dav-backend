class AddEmailConfirmedAndEmailUnconfirmedToAppUserSnapshot < ActiveRecord::Migration[6.1]
  def change
   add_column :app_user_snapshots, :email_confirmed, :integer, default: 0
   add_column :app_user_snapshots, :email_unconfirmed, :integer, default: 0
  end
end
