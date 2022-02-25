class DeletePurchasesJob < ApplicationJob
	queue_as :default

	def perform(*args)
		# Delete not completed purchases which are older than one day
		Purchase.where(completed: false).where("created_at < ?", DateTime.now - 1.day).each do |purchase|
			# Delete the PaymentIntent
			Stripe::PaymentIntent.cancel(purchase.payment_intent_id)
			purchase.destroy!
		end
	end
end
