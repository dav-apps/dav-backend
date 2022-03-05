class DeleteSessionsJob < ApplicationJob
	queue_as :default

	def perform(*args)
		# Delete sessions which were not used in the last 3 months
		Session.all.where("updated_at < ?", DateTime.now - 4.months).each do |session|
			session.destroy!
		end
	end
end
