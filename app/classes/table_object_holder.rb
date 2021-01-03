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
end