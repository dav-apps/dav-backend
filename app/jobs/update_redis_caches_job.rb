class UpdateRedisCachesJob < ApplicationJob
	queue_as :default

	def perform(*args)
		RedisTableObjectOperation.all.each do |operation|
			if operation.operation == "delete"
				begin
					# Remove the table object and properties from redis
					UtilsService.redis.del("table_object:#{operation.table_object_uuid}")

					property_keys = UtilsService.redis.keys("table_object_property:*:*:#{operation.table_object_uuid}:*")

					property_keys.each do |key|
						UtilsService.redis.del(key)
					end

					operation.destroy!
				rescue => e
				end
			else
				obj = TableObject.find_by(uuid: operation.table_object_uuid)

				if !obj.nil?
					# Update the table object on redis
					UtilsService.save_table_object_in_redis(obj)
				end

				operation.destroy!
			end
		end
	end
end
