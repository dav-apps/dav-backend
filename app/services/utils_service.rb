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

	def self.update_used_storage(user, app, storage_change)
		return if user.nil?

		# Update the used_storage of the user
		user.used_storage += storage_change
		user.save

		return if app.nil?

		app_user = AppUser.find_by(user: user, app: app)
		return if app_user.nil?

		# Update the used_storage of the app_user
		app_user.used_storage += storage_change
		app_user.save
	end

	def self.generate_table_object_etag(table_object)
		# uuid,property1Name:property1Value,property2Name:property2Value,...
		etag_string = table_object.uuid

		table_object.table_object_properties.each do |property|
			etag_string += ",#{property.name}:#{property.value}"
		end

		Digest::MD5.hexdigest(etag_string)
	end

	def self.create_property_type(table, name, value)
		# Check if a property type with the name already exists
		return if TablePropertyType.find_by(table_id: table.id, name: name)

		# Get the data type of the property value
		data_type = get_data_type_of_value(value)

		# Create the property type
		property_type = TablePropertyType.new(table_id: table.id, name: name, data_type: data_type)
		ValidationService.raise_unexpected_error(!property_type.save)
	end

	def self.get_data_type_of_value(value)
		return 1 if value.is_a?(TrueClass) || value.is_a?(FalseClass)
		return 2 if value.is_a?(Integer)
		return 3 if value.is_a?(Float)
		return 0
	end

	def self.convert_value_to_data_type(value, data_type)
		# Try to convert the value from string to the specified type
		# Return the original value if the parsing throws an exception
		return value == "true" if data_type == 1
		return Integer value rescue value if data_type == 2
		return Float value rescue value if data_type == 3
		return value
	end

	def self.find_data_type(property_types, name)
		property_type = property_types.find { |type| type.name == name }
		return property_type ? property_type.data_type : 0
	end

	def self.get_file_size(file)
		file.class == StringIO ? file.size : File.size(file)
	end

	def self.get_env_class_name(value)
		class_name = "string"

		if value.is_a?(TrueClass) || value.is_a?(FalseClass)
			class_name = "bool"
		elsif value.is_a?(Integer)
			class_name = "int"
		elsif value.is_a?(Float)
			class_name = "float"
		elsif value.is_a?(Array)
			content_class_name = get_env_class_name(value[0])
			class_name = "array:#{content_class_name}"
		end

		return class_name
	end
	
	def self.convert_env_value(class_name, value)
		if class_name == "bool"
			return value == "true"
		elsif class_name == "int"
			return value.to_i
		elsif class_name == "float"
			return value.to_f
		elsif class_name.include?(':')
			parts = class_name.split(':')

			if parts[0] == "array"
				array = Array.new

				value.split(',').each do |val|
					array.push(convert_env_value(parts[1], val))
				end

				return array
			else
				return value
			end
		end

		return value
	end
end