class AddEmailConfirmedAndEmailUnconfirmedToUserSnapshot < ActiveRecord::Migration[6.1]
  def change
   add_column :user_snapshots, :email_confirmed, :integer, default: 0
   add_column :user_snapshots, :email_unconfirmed, :integer, default: 0
  end
end
