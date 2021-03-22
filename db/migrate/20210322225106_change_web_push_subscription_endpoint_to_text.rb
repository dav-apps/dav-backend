class ChangeWebPushSubscriptionEndpointToText < ActiveRecord::Migration[6.0]
  def change
	change_column :web_push_subscriptions, :endpoint, :text
  end
end
