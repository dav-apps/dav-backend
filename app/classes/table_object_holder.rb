class TableObjectHolder
	attr_reader :obj, :properties, :values

	def initialize(obj)
		@properties = Array.new
		@values = Hash.new

		if obj.is_a?(Hash)
			# obj is a Hash
			@obj = TableObject.new(
				id: obj["id"],
				uuid: obj["uuid"],
				user_id: obj["user_id"],
				table_id: obj["table_id"],
				file: obj["file"],
				etag: obj["etag"]
			)

			obj["properties"].each do |key, value|
				@properties.push(TableObjectProperty.new(
					name: key,
					value: value
				))
				@values[key] = value
			end
		else
			# obj is a TableObject
			@obj = obj

			# Try to get the table object from redis
			redis = UtilsService.get_redis
			obj_data_json = redis.get("table_object:#{obj.uuid}")

			if obj_data_json.nil?
				obj.table_object_properties.each do |prop|
					@properties.push(prop)
					@values[prop.name] = prop.value
				end

				UtilsService.save_table_object_in_redis(obj)
			else
				obj_data = JSON.parse(obj_data_json)

				obj_data["properties"].each do |key, value|
					@properties.push(TableObjectProperty.new(
						name: key,
						value: value
					))
					@values[key] = value
				end
			end
		end
	end

	def id
		return nil if @obj.nil?
		@obj.id
	end

	def uuid
		return nil if @obj.nil?
		@obj.uuid
	end

	def user_id
		return nil if @obj.nil?
		@obj.user_id
	end

	def user
		return nil if @obj.nil?
		User.find_by(id: @obj.user_id)
	end

	def table_id
		return nil if @obj.nil?
		@obj.table_id
	end

	def [](name)
		return nil if @obj.nil?

		if name == "id"
			@obj.id
		elsif name == "uuid"
			@obj.uuid
		elsif name == "user_id"
			@obj.user_id
		elsif name == "table_id"
			@obj.table_id
		else
			@values[name]
		end
	end

	def []=(name, value)
		# Set the appropriate property value
		prop = @properties.find{ |p| p.name == name }

		if !value.nil? && !value.is_a?(String)
			UtilsService.create_property_type(@obj.table, name, value)
			value = value.to_s
		end

		if prop.nil?
			return nil if value.nil? || (value.is_a?(String) && value.length == 0)

			# Create a new property
			prop = TableObjectProperty.create(
				table_object: @obj,
				name: name,
				value: value
			)

			@properties.push(prop)
		elsif !prop.nil? && (value.nil? || value.length == 0)
			if prop.id.nil?
				# Find the property in the database
				prop = TableObjectProperty.find_by(table_object_id: @obj.id, name: name)
			end

			# Delete the property
			prop.destroy!
		else
			return value if prop.value == value
			save_new_value = true
			old_prop = prop

			if prop.id.nil?
				# Find the property in the database
				prop = TableObjectProperty.find_by(table_object_id: @obj.id, name: name)

				if prop.nil?
					prop = TableObjectProperty.create(
						table_object: @obj,
						name: name,
						value: value
					)

					# Replace the property in the properties
					@properties.delete(old_prop)
					@properties.push(prop)

					save_new_value = false
				end
			end

			if save_new_value
				# Set the value of the existing property
				prop.value = value
				prop.save
			end
		end

		# Update the local values
		@values[name] = value

		# Create the TableObjectChange
		TableObjectChange.create(table_object: @obj)

		# Remove the table object from redis
		redis = UtilsService.get_redis
		redis.del("table_object:#{@obj.uuid}")

		return value
	end
end