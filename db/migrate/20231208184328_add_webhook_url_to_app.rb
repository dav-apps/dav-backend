class AddWebhookUrlToApp < ActiveRecord::Migration[7.0]
  def change
    add_column :apps, :webhook_url, :string
  end
end
