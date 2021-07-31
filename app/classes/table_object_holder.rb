class TableObjectHolder
	attr_reader :obj, :properties, :values

	def initialize(obj)
		@obj = obj
		@properties = Array.new
		@values = Hash.new

		obj.table_object_properties.each do |prop|
			@properties.push(prop)
			@values[prop.name] = prop.value
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

		if prop.nil?
			# Create a new property
			prop = TableObjectProperty.create(
				table_object: @obj,
				name: name,
				value: value
			)

			# Update the local values
			@values[name] = value
			@properties.push(prop)
			return value
		else
			# Set the value of the existing property
			prop.value = value
			prop.save

			# Update the local values
			@values[name] = value
		end
	end
end