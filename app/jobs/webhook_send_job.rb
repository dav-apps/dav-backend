class WebhookSendError < StandardError
end

class WebhookSendJob < ApplicationJob
	queue_as :default
	retry_on WebhookSendError

	def perform(*args)
		purchase = Purchase.find_by(id: args[0])
		return if purchase.nil?

		purchase.table_objects.each do |obj|
			webhook_url = obj.table.app.webhook_url
			next if webhook_url.nil?

			res = HTTParty.put(
				webhook_url,
				body: {
					type: args[1],
					uuid: obj.uuid
				}.to_json,
				headers: {
					'Content-Type' => 'application/json',
					'Authorization': ENV["WEBHOOK_KEY"]
				}
			)

			raise WebhookSendError if res.code != 200
		end
	end
end
