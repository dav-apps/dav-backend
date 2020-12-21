class UtilsService
	def self.get_total_storage(plan, confirmed)
		storage_unconfirmed = 1000000000 	# 1 GB
      storage_on_free_plan = 2000000000 	# 2 GB
      storage_on_plus_plan = 15000000000 	# 15 GB
      storage_on_pro_plan = 50000000000   # 50 GB

		if !confirmed
			return storage_unconfirmed
      elsif plan == 1	# User is on dav Plus
			return storage_on_plus_plan
		elsif plan == 2	# User is on dav Pro
			return storage_on_pro_plan
		else
			return storage_on_free_plan
		end
	end

	def self.generate_table_object_etag(table_object)
		# uuid,property1Name:property1Value,property2Name:property2Value,...
		etag_string = table_object.uuid

		table_object.table_object_properties.each do |property|
			etag_string += ",#{property.name}:#{property.value}"
		end

		Digest::MD5.hexdigest(etag_string)
	end
end