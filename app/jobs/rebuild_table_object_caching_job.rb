class RebuildTableObjectCachingJob < ApplicationJob
	queue_as :default

	def perform(*args)
		# Go through each TableObject and save it in redis
		if args.count == 0
			TableObject.all.each do |table_object|
				UtilsService.save_table_object_in_redis(table_object)
			end
		else
			app = App.find(args[0])

			if !app.nil?
				app.tables.each do |table|
					table.table_objects.each do |table_object|
						UtilsService.save_table_object_in_redis(table_object)
					end
				end
			end
		end
	end
end
