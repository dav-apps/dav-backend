require 'blurhash'
require 'rmagick'

class DavExpressionRunner
	def run(props)
		# Get the runtime variables
		@api_slot = props[:api_slot]
		@vars = props[:vars]
		@functions = Hash.new
		@errors = Array.new
		@request = props[:request]
		@response = {
			dependencies: Array.new
		}

		# Parse and execute the commands
		@parser = Sexpistol.new
		@parser.ruby_keyword_literals = true
		ast = @parser.parse_string(props[:commands])

		# Stop the execution of the program if this is true
		@execution_stopped = false

		# Skip the current round in the loop if this is true
		@continue_loop = false

		# Stop the current for loop if this is true
		@break_loop = false

		ast.each do |element|
			break if @execution_stopped
			execute_command(element, @vars)
		end

		# Return the response
		return @response
	end

	private
	def execute_command(command, vars)
		return nil if @execution_stopped
		return nil if @errors.count > 0
		return nil if @continue_loop
		return nil if @break_loop

		if command.class == Array
			if command[0].class == Array && (!command[1] || command[1].class == Array)
				# Command contains commands
				result = nil
				command.each do |c|
					result = execute_command(c, vars)
				end
				return result
			end

			# Command is a function call
			case command[0]
			when :var
				# Check usage of []
				matchdata = command[1].to_s.match /^(?<varname>[a-zA-Z0-9_-]{1,})\[(?<value>[a-zA-Z0-9_\-\"]{0,})\]$/

				if !matchdata.nil?
					matchdata_varname = matchdata["varname"]
					matchdata_value = matchdata["value"]

					if !matchdata_value.nil?
						if matchdata_value[0] == "\"" && matchdata_value[-1] == "\""
							vars[matchdata_varname][matchdata_value[1..-2]] = execute_command(command[2], vars)
						else
							vars[matchdata_varname][execute_command(matchdata_value.to_sym, vars)] = execute_command(command[2], vars)
						end
					end
				elsif command[1].to_s.include?('..')
					parts = command[1].to_s.split('..')
					last_part = parts.pop
					current_var = vars

					parts.each do |part|
						if current_var.is_a?(Hash)
							part_value = execute_command(part, vars)
							return nil if !part_value.is_a?(String)

							current_var = current_var[part_value]
						else
							return nil
						end
					end

					if current_var.is_a?(Hash)
						last_part_value = execute_command(last_part, vars)
						return nil if !last_part_value.is_a?(String)

						current_var[last_part_value] = execute_command(command[2], vars)
					end

					return nil
				elsif command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop
					current_var = vars
					holder = nil

					parts.each do |part|
						if current_var.is_a?(Hash)
							current_var = current_var[part]
						elsif current_var.is_a?(TableObject) && part == "properties"
							current_var = current_var.table_object_properties
						elsif current_var.is_a?(TableObjectHolder) && part == "properties"
							holder = current_var
							current_var = current_var.values
						else
							return nil
						end
					end

					if current_var.is_a?(Hash)
						if holder
							prop = holder.properties.find{ |property| property.name == last_part }

							if !prop.nil?
								# Update the value of the property
								prop.value = execute_command(command[2], vars)
								prop.save

								# Update the values Hash of the TableObjectHolder
								holder.values[prop.name] = prop.value

								return prop.value
							else
								# Create a new property
								prop = TableObjectProperty.new(table_object: holder.obj, name: last_part, value: execute_command(command[2], vars))
								prop.save
								holder.values[last_part] = prop.value
								holder.properties.push(prop)
								return prop.value
							end
						else
							current_var[last_part] = execute_command(command[2], vars)
						end
					end
				else
					vars[command[1].to_s] = execute_command(command[2], vars)
				end

				return nil
			when :return
				return execute_command(command[1], vars)
			when :hash
				hash = Hash.new
				i = 1

				while !command[i].nil?
					hash[command[i][0].to_s] = execute_command(command[i][1], vars)
					i += 1
				end

				return hash
			when :list
				list = Array.new
				i = 1

				while !command[i].nil?
					result = execute_command(command[i], vars)
					list.push(result) if result != nil
					i += 1
				end

				return list
			when :if
				if execute_command(command[1], vars)
					return execute_command(command[2], vars)
				else
					i = 3
					while !command[i].nil?
						if command[i] == :elseif && execute_command(command[i + 1], vars)
							return execute_command(command[i + 2], vars)
						elsif command[i] == :else
							return execute_command(command[i + 1], vars)
						end
						i += 3
					end
				end
			when :for
				return nil if command[2] != :in

				array = execute_command(command[3], vars)
				return nil if array.class != Array
				var_name = command[1]
				commands = command[4]

				array.each do |entry|
					break if @break_loop
					next if @continue_loop

					vars[var_name.to_s] = entry
					execute_command(commands, vars)
				end

				@continue_loop = false
				@break_loop = false
			when :continue
				@continue_loop = true
				return nil
			when :break
				@break_loop = true
				return nil
			when :def
				# Function definition
				name = command[1].to_s
				function = Hash.new

				# Get the function parameters
				parameters = Array.new
				command[2].each do |parameter|
					parameters.push(parameter.to_s)
				end

				function["parameters"] = parameters
				function["commands"] = command[3]
				@functions[name] = function
				return nil
			when :func
				# Function call
				name = command[1]
				function = @functions[name.to_s]

				if function
					# Clone the vars for the function call
					args = Marshal.load(Marshal.dump(vars))

					i = 0
					function["parameters"].each do |param|
						args[param] = execute_command(command[2][i], vars)
						i += 1
					end

					return execute_command(function["commands"], args)
				else
					# Try to get the function from the database
					function = ApiFunction.find_by(api_slot: @api_slot, name: name)
					
					if function
						# Clone the vars for the function call
						args = Marshal.load(Marshal.dump(vars))
						params = Array.new

						i = 0
						function.params.split(',').each do |param|
							args[param] = execute_command(command[2][i], vars)
							params.push(param)
							i += 1
						end

						ast_parent = Array.new
						ast = @parser.parse_string(function.commands)

						ast.each do |element|
							ast_parent.push(element)
						end

						# Save the function in the functions variable for later use
						func = Hash.new
						func["commands"] = ast_parent
						func["parameters"] = params
						@functions[function.name] = func

						return execute_command(ast_parent, args)
					end
				end
			when :catch
				# Execute the commands in the first argument
				result = execute_command(command[1], vars)

				if @errors.length > 0
					# Add the errors to the variables and execute the commands in the second argument
					vars["errors"] = Array.new

					while @errors.length > 0
						vars["errors"].push(@errors.pop)
					end

					result = execute_command(command[2], vars)
				end

				return result
			when :throw_errors
				# Add the errors to the errors array
				i = 1
				errors = Array.new

				while !command[i].nil?
					errors.push(execute_command(command[i], vars))
					i += 1
				end

				errors.each do |e|
					@errors.push(e)
				end

				return @errors
			when :log
				result = execute_command(command[1], vars)
				puts result
				return result
			when :log_time
				return log_time(command[1])
			when :to_int
				return execute_command(command[1], vars).to_i
			when :is_nil
				return execute_command(command[1], vars) == nil
			when :parse_json
				json = execute_command(command[1], vars)
				return nil if json.size < 2
				return JSON.parse(json)
			when :get_header
				return @request[:headers][command[1].to_s]
			when :get_param
				return @request[:params][command[1].to_s]
			when :get_body
				if @request[:body].class == StringIO
					return @request[:body].string
				elsif @request[:body].class == Tempfile
					return @request[:body].read
				else
					return @request[:body]
				end
			when :get_error
				error = ApiError.find_by(api_slot: @api_slot, code: execute_command(command[1], vars))

				if !error.nil?
					result = Hash.new
					result["code"] = error.code
					result["message"] = error.message
					return result
				end
			when :get_env
				return vars["env"][execute_command(command[1], vars)]
			when :render_json
				result = execute_command(command[1], vars)
				status = execute_command(command[2], vars)

				@response[:data] = result
				@response[:status] = status == nil ? 200 : status
				@response[:file] = false

				@execution_stopped = true
			when :render_file
				result = execute_command(command[1], vars)
				type = execute_command(command[2], vars)
				filename = execute_command(command[3], vars)
				status = execute_command(command[4], vars)

				@response[:data] = result
				@response[:status] = status == nil ? 200 : status
				@response[:file] = true
				@response[:headers] = {"Content-Length" => result == nil ? 0 : result.size.to_s}
				@response[:type] = type
				@response[:filename] = filename

				@execution_stopped = true
			when :!
				return !execute_command(command[1], vars)
			else
				# Command might be a method call
				case command[0].to_s
				when "#"
					# It's a comment. Ignore this command
					return nil
				when "User.get"		# id
					return User.find_by(id: execute_command(command[1], vars).to_i)
				when "User.is_provider"		# user_id
					user_id = execute_command(command[1], vars)

					# Get the user
					user = User.find_by(id: user_id)

					if user.nil?
						error = Hash.new
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					return !user.provider.nil?
				when "Session.get"	# access_token
					token = execute_command(command[1], vars)
					session = Session.find_by(token: token)

					if session.nil?
						# Check if there is a session with old_token = token
						session = Session.find_by(old_token: token)

						if session.nil?
							# Session does not exist
							error = Hash.new
							error["code"] = 0
							@errors.push(error)
							return @errors
						else
							# The old token was used
							# Delete the session, as the token may be stolen
							session.destroy!
							error = Hash.new
							error["code"] = 1
							@errors.push(error)
							return @errors
						end
					else
						# Check if the session needs to be renewed
						if Rails.env.production? && (Time.now - session.updated_at) > 1.day
							error = Hash.new
							error["code"] = 2
							@errors.push(error)
							return @errors
						end
					end

					return session
				when "Table.get"		# id
					table = Table.find_by(id: execute_command(command[1], vars).to_i)

					if !table.nil? && table.app != @api_slot.api.app
						# Action not allowed error
						error = Hash.new
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					return table
				when "Table.get_table_objects"		# id, user_id
					table = Table.find_by(id: execute_command(command[1], vars).to_i)
					return nil if !table

					if table.app != @api_slot.api.app
						# Action not allowed error
						error = Hash.new
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					user_id = execute_command(command[2], vars)
					if user_id.nil?
						objects = table.table_objects.to_a

						# Add the dependency to the dependencies of the response
						@response[:dependencies].push({
							name: "Table.get_table_objects",
							table_id: table.id
						})
					else
						objects = table.table_objects.where(user_id: user_id.to_i).to_a

						# Add the dependency to the dependencies of the response
						@response[:dependencies].push({
							name: "Table.get_table_objects",
							user_id: user_id.to_i,
							table_id: table.id
						})
					end

					holders = Array.new
					objects.each { |obj| holders.push(TableObjectHolder.new(obj)) }

					return holders
				when "TableObject.create"	# user_id, table_id, properties
					# Get the table
					table = Table.find_by(id: execute_command(command[2], vars))
					error = Hash.new

					# Check if the table exists
					if table.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Check if the table belongs to the same app as the api
					if table.app != @api_slot.api.app
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Check if the user exists
					user = User.find_by(id: execute_command(command[1], vars))
					if user.nil?
						error["code"] = 2
						@errors.push(error)
						return @errors
					end

					# Create the table object
					obj = TableObject.new
					obj.user = user
					obj.table = table
					obj.uuid = SecureRandom.uuid

					if !obj.save
						# Unexpected error
						error["code"] = 3
						@errors.push(error)
						return @errors
					end

					# Create the properties
					properties = execute_command(command[3], vars)
					properties.each do |key, value|
						prop = TableObjectProperty.new
						prop.table_object = obj
						prop.name = key
						prop.value = value
						prop.save
					end

					# Create the TableObjectChange
					TableObjectChange.create(table_object: obj)

					# Return the table object
					return TableObjectHolder.new(obj)
				when "TableObject.create_file"	# user_id, table_id, ext, type, file
					# Get the table
					table = Table.find_by(id: execute_command(command[2], vars))
					error = Hash.new

					# Check if the table exists
					if table.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Check if the table belongs to the same app as the api
					if table.app != @api_slot.api.app
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Check if the user exists
					user = User.find_by(id: execute_command(command[1], vars))
					if user.nil?
						error["code"] = 2
						@errors.push(error)
						return @errors
					end

					# Create the table object
					obj = TableObject.new
					obj.user = user
					obj.table = table
					obj.uuid = SecureRandom.uuid
					obj.file = true

					ext = execute_command(command[3], vars)
					type = execute_command(command[4], vars)
					file = execute_command(command[5], vars)
					file_size = file.size

					# Check if the user has enough free storage
					free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage

					if free_storage < file_size
						error["code"] = 3
						@errors.push(error)
						return @errors
					end

					# Save the table object
					if !obj.save
						# Unexpected error
						error["code"] = 4
						@errors.push(error)
						return @errors
					end

					begin
						# Upload the file
						blob = BlobOperationsService.upload_blob(obj, StringIO.new(file))
						etag = blob.properties[:etag]

						# Remove the first and the last character of etag, because they are "" for whatever reason
						etag = etag[1...etag.size-1]
					rescue Exception => e
						error["code"] = 5
						@errors.push(error)
						return @errors
					end

					# Save extension as property
					ext_prop = TableObjectProperty.new(table_object: obj, name: Constants::EXT_PROPERTY_NAME, value: ext)

					# Save etag as property
					etag_prop = TableObjectProperty.new(table_object: obj, name: Constants::ETAG_PROPERTY_NAME, value: etag)

					# Save the file size as property
					size_prop = TableObjectProperty.new(table_object: obj, name: Constants::SIZE_PROPERTY_NAME, value: file_size)

					# Save the content type as property
					type_prop = TableObjectProperty.new(table_object: obj, name: Constants::TYPE_PROPERTY_NAME, value: type)

					# Update the used storage
					UtilsService.update_used_storage(user, table.app, file_size)

					# Save that user uses the app
					app_user = AppUser.find_by(app: table.app, user: user)
					if app_user.nil?
						app_user = AppUser.new(app: table.app, user: user)
						app_user.save
					end

					# Create the properties
					if !ext_prop.save || !etag_prop.save || !size_prop.save || !type_prop.save
						error["code"] = 6
						@errors.push(error)
						return @errors
					end

					return TableObjectHolder.new(obj)
				when "TableObject.get"	# uuid
					obj = TableObject.find_by(uuid: execute_command(command[1], vars))
					return nil if obj.nil?

					# Check if the table of the table object belongs to the same app as the api
					if obj.table.app != @api_slot.api.app
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Add the dependency to the dependencies of the response
					@response[:dependencies].push({
						name: "TableObject.get",
						table_object_id: obj.id
					})

					return TableObjectHolder.new(obj)
				when "TableObject.get_file"	# uuid
					obj = TableObject.find_by(uuid: execute_command(command[1], vars))
					return nil if !obj.file

					# Check if the table of the table object belongs to the same app as the api
					if obj.table.app != @api_slot.api.app
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					begin
						download_result = BlobOperationsService.download_blob(obj)
						return download_result[1]
					rescue => e
						return nil
					end
				when "TableObject.update"	# uuid, properties
					# Get the table object
					obj = TableObject.find_by(uuid: execute_command(command[1], vars))
					error = Hash.new

					# Check if the table object exists
					if obj.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Make sure the object is not a file
					if obj.file
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Check if the table of the table object belongs to the same app as the api
					if obj.table.app != @api_slot.api.app
						error["code"] = 2
						@errors.push(error)
						return @errors
					end

					# Update the properties of the table object
					properties = execute_command(command[2], vars)
					properties.each do |key, value|
						next if !value
						prop = TableObjectProperty.find_by(table_object: obj, name: key)

						if value.length > 0
							if prop.nil?
								# Create the property
								new_prop = TableObjectProperty.new(name: key, value: value, table_object: obj)
								ValidationService.raise_validation_errors(ValidationService.raise_unexpected_error(!new_prop.save))
							else
								# Update the property
								prop.value = value
								ValidationService.raise_validation_errors(ValidationService.raise_unexpected_error(!prop.save))
							end
						elsif !prop.nil?
							# Delete the property
							prop.destroy!
						end
					end

					# Create the TableObjectChange
					TableObjectChange.create(table_object: obj)

					return TableObjectHolder.new(obj)
				when "TableObject.update_file"	# uuid, ext, type, file
					# Get the table object
					obj = TableObject.find_by(uuid: execute_command(command[1], vars))
					error = Hash.new

					# Check if the table object exists
					if obj.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Check if the table object is a file
					if !obj.file
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Check if the table of the table object belongs to the same app as the api
					if obj.table.app != @api_slot.api.app
						error["code"] = 2
						@errors.push(error)
						return @errors
					end

					# Get the properties
					ext_prop = TableObjectProperty.find_by(table_object: obj, name: Constants::EXT_PROPERTY_NAME)
					etag_prop = TableObjectProperty.find_by(table_object: obj, name: Constants::ETAG_PROPERTY_NAME)
					size_prop = TableObjectProperty.find_by(table_object: obj, name: Constants::SIZE_PROPERTY_NAME)
					type_prop = TableObjectProperty.find_by(table_object: obj, name: Constants::TYPE_PROPERTY_NAME)

					ext = execute_command(command[2], vars)
					type = execute_command(command[3], vars)
					file = execute_command(command[4], vars)
					user = obj.user

					file_size = file.size
					old_file_size = size_prop ? size_prop.value.to_i : 0
					file_size_diff = file_size - old_file_size
					free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage

					# Check if the user has enough free storage
					if free_storage < file_size_diff
						error["code"] = 3
						@errors.push(error)
						return @errors
					end

					begin
						# Upload the new file
						blob = BlobOperationsService.upload_blob(obj, StringIO.new(file))
						etag = blob.properties[:etag]
						etag = etag[1...etag.size-1]
					rescue Exception => e
						error["code"] = 4
						@errors.push(error)
						return @errors
					end

					# Update or create the properties
					if ext_prop.nil?
						ext_prop = TableObjectProperty.new(table_object: obj, name: Constants::EXT_PROPERTY_NAME, value: ext)
					else
						ext_prop.value = ext
					end

					if etag_prop.nil?
						etag_prop = TableObjectProperty.new(table_object: obj, name: Constants::ETAG_PROPERTY_NAME, value: etag)
					else
						etag_prop.value = etag
					end

					if size_prop.nil?
						size_prop = TableObjectProperty.new(table_object: obj, name: Constants::SIZE_PROPERTY_NAME, value: file_size)
					else
						size_prop.value = file_size
					end

					if type_prop.nil?
						type_prop = TableObjectProperty.new(table_object: obj, name: Constants::TYPE_PROPERTY_NAME, value: type)
					else
						type_prop.value = type
					end

					# Update the used storage
					UtilsService.update_used_storage(obj.user, obj.table.app, file_size_diff)

					# Save the properties
					if !ext_prop.save || !etag_prop.save || !size_prop.save || !type_prop.save
						error["code"] = 5
						@errors.push(error)
						return @errors
					end

					return TableObjectHolder.new(obj)
				when "TableObject.set_price"	# uuid, price, currency
					uuid = execute_command(command[1], vars)
					price = execute_command(command[2], vars)
					currency = execute_command(command[3], vars)

					# Get the table object
					obj = TableObject.find_by(uuid: uuid)
					error = Hash.new

					# Check if the table object exists
					if obj.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Check if the table of the table object belongs to the same app as the api
					if obj.table.app != @api_slot.api.app
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Try to get the price of the table object with the currency
					obj_price = obj.table_object_prices.find_by(currency: currency.downcase)

					if obj_price.nil?
						# Create a new price
						obj_price = TableObjectPrice.new(
							table_object: obj,
							price: price,
							currency: currency
						)
					else
						# Update the price
						obj_price.price = price
					end

					if !obj_price.save
						error["code"] = 2
						@errors.push(error)
						return @errors
					end
				when "TableObject.get_price"	# uuid, currency
					uuid = execute_command(command[1], vars)
					currency = execute_command(command[2], vars)

					# Get the table object
					obj = TableObject.find_by(uuid: uuid)
					error = Hash.new

					# Check if the table object exists
					return nil if obj.nil?

					# Check if the table of the table object belongs to the same app as the api
					if obj.table.app != @api_slot.api.app
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Try to get the price of the table object with the currency
					obj_price = obj.table_object_prices.find_by(currency: currency.downcase)
					return nil if obj_price.nil?
					return obj_price.price
				when "TableObjectUserAccess.create"	# table_object_id, user_id, table_alias
					# Check if there is already an TableObjectUserAccess object
					error = Hash.new
					table_object_id = execute_command(command[1], vars)
					user_id = execute_command(command[2], vars)
					table_alias = execute_command(command[3], vars)

					if table_object_id.is_a?(String)
						# Get the id of the table object
						obj = TableObject.find_by(uuid: table_object_id)

						if obj.nil?
							error["code"] = 0
							@errors.push(error)
							return @errors
						end

						table_object_id = obj.id
					end

					# Try to find the table
					table = Table.find_by(id: table_alias)
					if table.nil?
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Find the access and return it
					access = TableObjectUserAccess.find_by(
						table_object_id: table_object_id,
						user_id: user_id,
						table_alias: table_alias
					)

					if access.nil?
						access = TableObjectUserAccess.create(
							table_object_id: table_object_id,
							user_id: user_id,
							table_alias: table_alias
						)
					end

					return access
				when "Collection.add_table_object"	# collection_name, table_object_id
					error = Hash.new
					collection_name = execute_command(command[1], vars)
					table_object_id = execute_command(command[2], vars)

					if table_object_id.is_a?(String)
						# Get the table object by uuid
						obj = TableObject.find_by(uuid: table_object_id)
					else
						# Get the table object by id
						obj = TableObject.find_by(id: table_object_id)
					end

					if obj.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Try to find the collection
					collection = Collection.find_by(name: collection_name, table: obj.table)

					if !collection
						# Create the collection
						collection = Collection.new(name: collection_name, table: obj.table)
						collection.save
					end

					# Try to find the TableObjectCollection
					obj_collection = TableObjectCollection.find_by(table_object: obj, collection: collection)

					if obj_collection.nil?
						# Create the TableObjectCollection
						obj_collection = TableObjectCollection.new(table_object: obj, collection: collection)
						obj_collection.save
					end

					# Create the TableObjectChange
					TableObjectChange.create(collection: collection)

					return obj_collection
				when "Collection.remove_table_object"	# collection_name, table_object_id
					error = Hash.new
					collection_name = execute_command(command[1], vars)
					table_object_id = execute_command(command[2], vars)

					if table_object_id.is_a?(String)
						# Get the table object by uuid
						obj = TableObject.find_by(uuid: table_object_id)
					else
						# Get the table object by id
						obj = TableObject.find_by(id: table_object_id)
					end

					if obj.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Find the collection
					collection = Collection.find_by(name: collection_name, table: obj.table)

					if collection.nil?
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Find and delete the TableObjectCollection
					obj_collection = TableObjectCollection.find_by(table_object: obj, collection: collection)
					obj_collection.destroy! if !obj_collection.nil?

					# Create the TableObjectChange
					TableObjectChange.create(collection: collection)
				when "Collection.get_table_objects"	# table_id, collection_name
					error = Hash.new
					table_id = execute_command(command[1], vars)
					collection_name = execute_command(command[2], vars)

					# Try to find the table
					table = Table.find_by(id: table_id)

					if table.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Try to find the collection
					collection = Collection.find_by(name: collection_name, table: table)

					if collection.nil?
						return Array.new
					else
						# Add the dependency to the dependencies of the response
						@response[:dependencies].push({
							name: "Collection.get_table_objects",
							collection_id: collection.id
						})

						holders = Array.new
						collection.table_objects.each { |obj| holders.push(TableObjectHolder.new(obj)) }
						return holders
					end
				when "TableObject.find_by_property"	# user_id, table_id, property_name, property_value, exact = true
					all_user = command[1] == "*"
					user_id = all_user ? -1 : execute_command(command[1], vars)
					table_id = execute_command(command[2], vars)
					property_name = execute_command(command[3], vars)
					property_value = execute_command(command[4], vars)
					exact = command[5] != nil ? execute_command(command[5], vars) : true

					objects = Array.new

					if all_user
						TableObject.where(table_id: table_id).each do |table_object|
							if exact
								# Look for the exact property value
								property = TableObjectProperty.find_by(table_object: table_object, name: property_name, value: property_value)
								objects.push(table_object) if property
							else
								# Look for the properties that contain the property value
								properties = TableObjectProperty.where(table_object: table_object, name: property_name)

								contains_value = false
								properties.each do |prop|
									if prop.value.include? property_value
										contains_value = true
										break
									end
								end

								objects.push(table_object) if contains_value
							end
						end

						# Add the dependency to the dependencies of the response
						@response[:dependencies].push({
							name: "TableObject.find_by_property",
							table_id: table_id
						})
					else
						TableObject.where(user_id: user_id, table_id: table_id).each do |table_object|
							if exact
								# Look for the exact property value
								property = TableObjectProperty.find_by(table_object: table_object, name: property_name, value: property_value)
								objects.push(table_object) if !property.nil?
							else
								# Look for properties that contain the property value
								properties = TableObjectProperty.where(table_object: table_object, name: property_name)
		
								contains_value = false
								properties.each do |prop|
									if prop.value.include? property_value
										contains_value = true
										break
									end
								end

								objects.push(table_object) if contains_value
							end
						end

						# Add the dependency to the dependencies of the response
						@response[:dependencies].push({
							name: "TableObject.find_by_property",
							user_id: user_id,
							table_id: table_id
						})
					end

					holders = Array.new
					objects.each { |obj| holders.push(TableObjectHolder.new(obj)) }
					return holders
				when "Purchase.create"	# user_id, provider_name, provider_image, product_name, product_image, price, currency, table_objects
					user_id = execute_command(command[1], vars)
					provider_name = execute_command(command[2], vars)
					provider_image = execute_command(command[3], vars)
					product_name = execute_command(command[4], vars)
					product_image = execute_command(command[5], vars)
					price = execute_command(command[6], vars)
					currency = execute_command(command[7], vars)
					table_objects = execute_command(command[8], vars)
					error = Hash.new

					# Get the user
					user = User.find_by(id: user_id)

					if user.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					# Check the property types
					if !provider_name.is_a?(String) || !provider_image.is_a?(String) || !product_name.is_a?(String) || !product_image.is_a?(String) || !price.is_a?(Integer) || !currency.is_a?(String) || !table_objects.is_a?(Array)
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					# Validate the price
					if price < 0
						error["code"] = 2
						@errors.push(error)
						return @errors
					end

					# Make sure there is at least one table object
					if table_objects.count == 0
						error["code"] = 3
						@errors.push(error)
						return @errors
					end

					# Get the table objects
					objs = Array.new

					table_objects.each do |uuid|
						obj = TableObject.find_by(uuid: uuid)

						if obj.nil?
							error["code"] = 4
							@errors.push(error)
							return @errors
						end

						objs.push(obj)
					end

					# Check if the table objects belong to the same user
					obj_user = objs.first.user
					i = 1

					while i < objs.count
						if objs[i].user != obj_user
							error["code"] = 5
							@errors.push(error)
							return @errors
						end

						i += 1
					end

					# Check if the user of the table objects has a provider
					if price > 0 && obj_user.provider.nil?
						error["code"] = 6
						@errors.push(error)
						return @errors
					end

					# Create the purchase
					purchase = Purchase.new(
						user: user,
						uuid: SecureRandom.uuid,
						provider_name: provider_name,
						provider_image: provider_image,
						product_name: product_name,
						product_image: product_image,
						price: price,
						currency: currency
					)

					if price == 0
						purchase.completed = true
					else
						# Create a stripe customer for the user, if the user has none
						if user.stripe_customer_id.nil?
							customer = Stripe::Customer.create(email: user.email)
							user.stripe_customer_id = customer.id
							ValidationService.raise_unexpected_error(!user.save)
						end

						# Create a payment intent
						begin
							payment_intent = Stripe::PaymentIntent.create({
								customer: user.stripe_customer_id,
								amount: price,
								currency: currency.downcase,
								confirmation_method: 'manual',
								application_fee_amount: (price * 0.2).round,
								transfer_data: {
									destination: obj_user.provider.stripe_account_id
								}
							})
						rescue Stripe::CardError => e
							error["code"] = 7
							@errors.push(error)
							return @errors
						end

						purchase.payment_intent_id = payment_intent.id
					end

					# Create the TableObjectPurchases
					objs.each do |obj|
						obj_purchase = TableObjectPurchase.new(
							table_object: obj,
							purchase: purchase
						)

						if !obj_purchase.save
							error["code"] = 8
							@errors.push(error)
							return @errors
						end
					end

					return purchase
				when "Purchase.get_table_object"	# purchase_id, user_id
					error = Hash.new
					purchase_id = execute_command(command[1], vars)
					user_id = execute_command(command[2], vars)

					purchase = Purchase.find_by(id: purchase_id)

					if purchase.nil?
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					user = User.find_by(id: user_id)

					if user.nil?
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					if purchase.user != user
						error["code"] = 2
						@errors.push(error)
						return @errors
					end

					if !purchase.completed
						error["code"] = 3
						@errors.push(error)
						return @errors
					end

					return TableObjectHolder.new(purchase.table_object)
				when "Purchase.find_by_user_and_table_object"		# user_id, table_object_id
					user_id = execute_command(command[1], vars)
					table_object_id = execute_command(command[2], vars)

					if table_object_id.class == Integer
						# table_object_id is id
						table_object = TableObject.find_by(id: table_object_id)
						return nil if table_object.nil?

						return table_object.purchases.find_by(user_id: user_id, completed: true)
					else
						# table_object_id is uuid
						table_object = TableObject.find_by(uuid: table_object_id)
						return nil if table_object.nil?

						return table_object.purchases.find_by(user_id: user_id, completed: true)
					end
				when "Math.round"	# var, rounding = 2
					var = execute_command(command[1], vars)
					rounding = execute_command(command[2], vars)
					rounding = 2 if rounding == nil
					return var if var.class != Float || rounding.class != Integer
					rounded_value = var.round(rounding)
					rounded_value = var.round if rounded_value == var.round
					return rounded_value
				when "Regex.match"	# string, regex
					string = execute_command(command[1], vars)
					regex = execute_command(command[2], vars)
					return Hash.new if string == nil || regex == nil
					match = regex.match(string)
					return match == nil ? Hash.new : match.named_captures
				when "Regex.check" # string, regex
					string = execute_command(command[1], vars)
					regex = execute_command(command[2], vars)
					return false if string == nil || regex == nil
					return regex.match?(string)
				when "Blurhash.encode"	# image_data
					image_data = execute_command(command[1], vars)

					begin
						image = Magick::ImageList.new
		
						if image_data.class == StringIO
							image.from_blob(image_data.string)
						elsif image_data.class == Tempfile
							image_data.rewind
							image.from_blob(image_data.read)
						else
							image.from_blob(image_data)
						end

						return Blurhash.encode(image.columns, image.rows, image.export_pixels)
					rescue
						return nil
					end
				when "Image.get_details"	# image_data
					image_data = execute_command(command[1], vars)

					begin
						result = Hash.new
						image = Magick::ImageList.new

						if image_data.class == StringIO
							image.from_blob(image_data.string)
						elsif image_data.class == Tempfile
							image_data.rewind
							image.from_blob(image_data.read)
						else
							image.from_blob(image_data)
						end

						result["width"] = image.columns
						result["height"] = image.rows
						return result
					rescue
						result["width"] = -1
						result["height"] = -1
						return result
					end
				end

				# Command might be an expression
				case command[1]
				when :==
					return execute_command(command[0], vars) == execute_command(command[2], vars)
				when :!=
					return execute_command(command[0], vars) != execute_command(command[2], vars)
				when :>
					return execute_command(command[0], vars) > execute_command(command[2], vars)
				when :<
					return execute_command(command[0], vars) < execute_command(command[2], vars)
				when :>=
					return execute_command(command[0], vars) >= execute_command(command[2], vars)
				when :<=
					return execute_command(command[0], vars) <= execute_command(command[2], vars)
				when :+, :-
					# Get all values
					values = Array.new
					i = 0

					while !command[i].nil?
						value = execute_command(command[i], vars)
						values.push(value)

						i += 2
					end

					result = values[0].class == String ? "" : 0
					i = -1
					j = 0

					while !command[i].nil?
						value = values[j]

						if result.class == String || value.class == String
							result = result.to_s + value.to_s
						elsif command[i] == :- && result.class != String
							result -= value
						else
							result += value
						end

						i += 2
						j += 1
					end

					return result
				when :*
					first_var = execute_command(command[0], vars)
					second_var = execute_command(command[2], vars)
					return nil if (first_var.class != Integer && first_var.class != Float) || (second_var.class != Integer && second_var.class != Float)
					return first_var * second_var
				when :/
					first_var = execute_command(command[0], vars)
					second_var = execute_command(command[2], vars)
					return nil if (first_var.class != Integer && first_var.class != Float) || (second_var.class != Integer && second_var.class != Float)
					return first_var / second_var
				when :%
					first_var = execute_command(command[0], vars)
					second_var = execute_command(command[2], vars)
					return nil if (first_var.class != Integer && first_var.class != Float) || (second_var.class != Integer && second_var.class != Float)
					return first_var % second_var
				when :and, :or
					result = execute_command(command[0], vars)
					i = 2

					while !command[i].nil?
						if command[i - 1] == :and
							result = execute_command(command[i], vars) && result
						elsif command[i - 1] == :or
							result = execute_command(command[i], vars) || result
						end

						i += 2
					end

					return result
				end

				if command[0].to_s.include?('.')
					# Get the value of the variable
					parts = command[0].to_s.split('.')
					function_name = parts.pop

					# Check for usage of []
					if (parts.size == 1) && (parts[0].match /^[a-zA-Z0-9_-]{1,}\[[a-zA-Z0-9_\-\"]{0,}\]$/)
						var = execute_command(parts[0], vars)
					else
						# Check if the variable exists
						return command[0] if !vars.include?(parts[0].split('#')[0])
						var = parts.size == 1 ? vars[parts[0]] : execute_command(parts.join('.'), vars)
					end

					if var.class == Array
						if function_name == "push"
							i = 1
							while command[i]
								result = execute_command(command[i], vars)
								var.push(result) if result != nil
								i += 1
							end
						elsif function_name == "contains"
							return var.include?(execute_command(command[1], vars))
						elsif function_name == "contains_all"
							comparing_array = execute_command(command[1], vars)
							intersection_array = (var & comparing_array)
							return intersection_array.size == comparing_array.size
						elsif function_name == "join"
							return "" if var.size == 0

							separator = execute_command(command[1], vars)
							result = var[0]

							for i in 1..var.size - 1 do
								result = result + separator + var[i]
							end

							return result
						elsif function_name == "select"
							start_pos = execute_command(command[1], vars)
							end_pos = execute_command(command[2], vars)
							return var[start_pos, end_pos]
						end
					elsif var.class == String
						if function_name == "split"
							return var.split(execute_command(command[1], vars))
						elsif function_name == "contains"
							return var.include?(execute_command(command[1], vars))
						end
					end
				end

				# Treat the command like a series of commands
				result = nil
				command.each do |c|
					result = execute_command(c, vars)
				end
				return result
			end
		elsif command.class == Regexp || !!command == command
			# Command is Regexp or boolean
			return command
		elsif command.class == String && command.size == 1
			return command
		elsif command.to_s.match /^[a-zA-Z0-9_-]{1,}\[[a-zA-Z0-9_\-\"]{0,}\]$/
			matchdata = command.to_s.match /^(?<varname>[a-zA-Z0-9_-]{1,})\[(?<value>[a-zA-Z0-9_\-\"]{0,})\]$/
			matchdata_varname = matchdata["varname"]
			matchdata_value = matchdata["value"]

			if matchdata_value[0] == "\"" && matchdata_value[-1] == "\""
				return vars[matchdata_varname][matchdata_value[1..-2]]
			else
				return vars[matchdata_varname][execute_command(matchdata_value.to_sym, vars)]
			end
		elsif command.to_s.include?('..')
			parts = command.to_s.split('..')
			last_part = parts.pop

			# Check if the variable exists
			return command if !vars.include?(parts[0].split('#')[0])
			var = execute_command(parts.join('..').to_sym, vars)
			last_part_value = vars[last_part]

			return var if !var.is_a?(Hash) || !last_part_value.is_a?(String)
			return var[last_part_value]
		elsif command.to_s.include?('.')
			# Return the value of the hash
			parts = command.to_s.split('.')
			last_part = parts.pop

			# Check for usage of []
			if (parts.size == 1) && (parts[0].match /^[a-zA-Z0-9_-]{1,}\[[a-zA-Z0-9_\-\"]{0,}\]$/)
				var = execute_command(parts[0], vars)
			else
				# Check if the variable exists
				return command if !vars.include?(parts[0].split('#')[0])
				var = execute_command(parts.join('.').to_sym, vars)
			end

			if last_part == "class"
				return var.class.to_s
			elsif var.class == Hash
				# Access index of array in hash
				if last_part.include?('#')
					parts = last_part.split('#')
					last_part = parts[0]
					int = (Integer(parts[1]) rescue nil)

					if var[last_part].class == Array && int
						return var[last_part][int]
					end
				end

				return var[last_part]
			elsif var.class == Array
				if last_part == "length"
					return var.count
				elsif last_part == "reverse"
					return var.reverse
				end
			elsif var.class == String
				if last_part == "length"
					return var.length
				elsif last_part == "upcase"
					return var.upcase
				elsif last_part == "downcase"
					return var.downcase
				elsif last_part == "to_i"
					return var.to_i
				end
			elsif var.class == Integer
				if last_part == "to_f"
					return var.to_f
				end
			elsif var.class == Float
				if last_part == "round"
					return var.round
				end
			elsif var.class == User
				return var[last_part]
			elsif var.class == Table
				if last_part == "table_objects"
					return var.table_objects.to_a
				else
					return var[last_part]
				end
			elsif var.class == Session
				if last_part == "user_id"
					return var.user_id
				elsif last_part == "app_id"
					return var.app_id
				end
			elsif var.class == TableObject
				if last_part == "properties"
					return var.table_object_properties
				else
					return var[last_part]
				end
			elsif var.class.to_s == "TableObjectProperty::ActiveRecord_Associations_CollectionProxy"
				props = var.where(name: last_part)
				return props[0].value if props.count > 0
				return nil
			elsif var.class == TableObjectHolder
				return var.values if last_part == "properties"
				return var.obj[last_part]
			elsif var.class == Purchase
				return var[last_part]
			end
		elsif command.to_s.include?('#')
			parts = command.to_s.split('#')
			var = vars[parts.first]

			if var.class == Array
				int = (Integer(parts[1]) rescue nil)

				if int
					return var[int]
				elsif vars[parts[1]]
					return var[vars[parts[1]]]
				else
					return nil
				end
			end
		elsif command.class == Symbol
			return vars[command.to_s] if vars.key?(command.to_s)
			return nil
		else
			return command
		end
	end

	def log_time(message = nil)
		current = Time.new
		@start = current if @start == nil

		time_diff = (current - @start).in_milliseconds

		puts "---------------------"
		if message == nil
			puts "#{time_diff.to_s} ms"
		else
			puts "#{message}: #{time_diff.to_s} ms"
		end
		puts "---------------------"

		@start = current
		return time_diff
	end
end