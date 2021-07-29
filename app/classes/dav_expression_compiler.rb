class DavExpressionCompiler
	def compile(props)
		@api = props[:api]
		@defined_functions = Array.new
		@functions_to_define = Array.new

		# Parse and compile the commands
		@parser = Sexpistol.new
		@parser.ruby_keyword_literals = true
		ast = @parser.parse_string(props[:commands])
		code = ""

		ast.each do |element|
			code += "#{compile_command(element)}\n"
		end

		# Define functions
		functions_code = ""
		@functions_to_define.each do |function|
			functions_code += compile_function_definition(function)
		end

		# Define built-in methods
		methods_code = "
			def _method_call(method_name, **params)
				errors = Array.new

				case method_name
				when 'parse_json'
					json = params[:json]

					if json.length < 2
						return {}
					else
						return JSON.parse(json)
					end
				when 'get_body'
					body = @vars[:body]

					if body.class == StringIO
						return body.string
					elsif body.class == Tempfile
						return body.read
					else
						return body
					end
				when 'get_error'
					error = ApiError.find_by(api: @vars[:api], code: params[:code])
					return {
						\"code\" => error.code,
						\"message\" => error.message
					}
				when 'Session.get'
					token = params[:access_token]
					session = Session.find_by(token: token)

					if session.nil?
						# Check if there is a session with old_token = token
						session = Session.find_by(old_token: token)

						if session.nil?
							# Session does not exist
							raise RuntimeError, [{\"code\" => 0}].to_json
						else
							# The old token was used
							# Delete the session, as the token may be stolen
							session.destroy!
							raise RuntimeError, [{\"code\" => 1}].to_json
						end
					else
						# Check if the session needs to be renewed
						if Rails.env.production? && (Time.now - session.updated_at) > 1.day
							raise RuntimeError, [{\"code\" => 2}].to_json
						end
					end

					return session
				when 'Table.get_table_objects'
					id = params[:id]
					user_id = params[:user_id]

					table = Table.find_by(id: id.to_i)
					return nil if !table

					if table.app != @vars[:api].app
						# Action not allowed error
						raise RuntimeError, [{\"code\" => 1}].to_json
					end

					if user_id.nil?
						objects = table.table_objects.to_a
					else
						objects = table.table_objects.where(user_id: user_id.to_i).to_a
					end

					return objects
				when 'TableObject.create'
					user_id = params[:user_id]
					table_id = params[:table_id]
					properties = params[:properties]

					# Get the table
					table = Table.find_by(id: table_id)

					# Check if the table exists
					if table.nil?
						raise RuntimeError, [{\"code\" => 0}].to_json
					end

					# Check if the table belongs to the same app as the api
					if table.app != @vars[:api].app
						raise RuntimeError, [{\"code\" => 1}].to_json
					end

					# Check if the user exists
					user = User.find_by(id: user_id)
					if user.nil?
						raise RuntimeError, [{\"code\" => 2}].to_json
					end

					# Create the table object
					obj = TableObject.new
					obj.user = user
					obj.table = table
					obj.uuid = SecureRandom.uuid

					if !obj.save
						# Unexpected error
						raise RuntimeError, [{\"code\" => 3}].to_json
					end

					# Create the properties
					properties.each do |key, value|
						prop = TableObjectProperty.new
						prop.table_object = obj
						prop.name = key
						prop.value = value
						prop.save
					end

					# Return the table object
					return obj
				when 'Collection.add_table_object'
					collection_name = params[:collection_name]
					table_object_id = params[:table_object_id]
					error = Hash.new

					if table_object_id.is_a?(String)
						# Get the table object by uuid
						obj = TableObject.find_by(uuid: table_object_id)
					else
						# Get the table object by id
						obj = TableObject.find_by(id: table_object_id)
					end

					if obj.nil?
						raise RuntimeError, [{\"code\" => 0}].to_json
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
				end
			end
		"

		return functions_code + methods_code + code
	end

	def run(code, api, request = nil)
		# Define necessary vars
		@vars = {
			api: api,
			env: Hash.new
		}

		api.api_env_vars.each do |env_var|
			@vars[:env][env_var.name] = UtilsService.convert_env_value(env_var.class_name, env_var.value)
		end

		if !request.nil?
			# Get the headers
			headers = Hash.new
			headers["Authorization"] = request.headers["Authorization"]
			headers["Content-Type"] = request.headers["Content-Type"]
			headers["Content-Disposition"] = request.headers["Content-Disposition"]

			# Get the query params
			# TODO

			@vars[:body] = request.body
			@vars[:headers] = headers
		end

		eval code
	end

	private
	def compile_command(command, nested = false)
		if command.class == Array
			if command[0].class == Array && (!command[1] || command[1].class == Array)
				# Command contains commands
				code = ""
				command.each do |c|
					code += "#{compile_command(c, nested)}\n"
				end
				return code
			end

			# Command is a function call
			case command[0]
			when :var
				if command[1].to_s.include?('..')
					parts = command[1].to_s.split('..')
					last_part = parts.pop

					return "#{compile_command(parts.join('..').to_sym, true)}[\"#{last_part}\"] = #{compile_command(command[2])}"
				elsif command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop

					return "#{compile_command(parts.join('.').to_sym, true)}[\"#{last_part}\"] = #{compile_command(command[2])}"
				else
					return "#{command[1]} = #{compile_command(command[2])}"
				end
			when :return
				return "return #{compile_command(command[1], true)}"
			when :hash
				compiled_commands = []
				i = 1

				while !command[i].nil?
					compiled_commands.push({
						name: command[i][0],
						command: compile_command(command[i][1], true)
					})
					i += 1
				end

				return "{}" if compiled_commands.size == 0
				result = "{\n"

				for i in 0..compiled_commands.size - 1
					compiled_command = compiled_commands[i]
					result += "\"#{compiled_command[:name]}\" => #{compiled_command[:command]}"
					result += ", " if !compiled_commands[i + 1].nil?
					result += "\n"
				end

				result += "}"
				return result
			when :list
				compiled_commands = []
				i = 1

				while !command[i].nil?
					compiled_commands.push(compile_command(command[i], true))
					i += 1
				end

				return "[]" if compiled_commands.size == 0
				result = "[\n"

				for i in 0..compiled_commands.size - 1
					result += compiled_commands[i].to_s
					result += ", " if !compiled_commands[i + 1].nil?
					result += "\n"
				end

				result += "].compact"
				return result
			when :if
				result = "if (#{compile_command(command[1], true)})\n"
				result += "#{compile_command(command[2])}\n"

				i = 3
				while !command[i].nil?
					if command[i] == :elseif
						result += "elsif #{compile_command(command[i + 1], true)}\n"
						result += "#{compile_command(command[i + 2])}\n"
					elsif command[i] == :else
						result += "else\n#{compile_command(command[i + 1])}\n"
					end

					i += 3
				end

				result += "end\n"
				return result
			when :for
				return nil if command[2] != :in
				varname = command[1]

				result = "#{command[3]}.each do |#{varname}|\n"
				result += "next if #{varname}.nil?\n"
				result += compile_command(command[4])
				result += "end\n"

				return result
			when :break
				return "break\n"
			when :def
				name = command[1].to_s
				result = "def #{name}("

				i = 0
				command[2].each do |parameter|
					result += ", " if i != 0
					result += parameter.to_s
					i += 1
				end

				result += ")\n"
				result += "#{compile_command(command[3])}\nend\n"

				# Save that the function is defined
				@defined_functions.push(name)

				return result
			when :func
				name = command[1].to_s

				# Check if the function is defined
				if !@defined_functions.include?(name)
					# Try to get the function from the database
					function = ApiFunction.find_by(api: @api, name: name)
					return "" if function.nil?

					@defined_functions.push(name)
					@functions_to_define.push(function)
				end

				# Call the function
				result = "#{name}("

				i = 0
				command[2].each do |parameter|
					result += ", " if i != 0
					result += compile_command(parameter, true).to_s
					i += 1
				end

				result += ")"
				result += "\nreturn @vars[:response] if !@vars[:response].nil?" if !nested

				return result
			when :catch
				result = "begin\n"
				result += "#{compile_command(command[1])}\n"
				result += "rescue RuntimeError => e\n"
				result += "errors = JSON.parse(e.message)\n"
				result += "#{compile_command(command[2])}\nend\n"
				return result
			when :throw_errors
				errors = "[\n"
				i = 1

				while !command[i].nil?
					errors += "#{compile_command(command[i], true)},\n"
					i += 1
				end

				errors += "].to_json"
				return "raise RuntimeError, #{errors}"
			when :log
				return "puts #{compile_command(command[1], true)}"
			when :to_int
				return "#{command[1]}.to_i"
			when :is_nil
				return "#{compile_command(command[1], true)}.nil?"
			when :parse_json
				return "_method_call('parse_json', json: #{compile_command(command[1], true)})"
			when :get_header
				return "@vars[:headers][#{compile_command(command[1], true)}]"
			when :get_body
				return "_method_call('get_body')"
			when :get_error
				return "_method_call('get_error', code: #{compile_command(command[1], true)})"
			when :get_env
				return "@vars[:env][#{compile_command(command[1], true)}]"
			when :render_json
				result = "@vars[:response] = {\n"
				result += "data: #{compile_command(command[1], true)},\n"
				result += "status: #{compile_command(command[2], true)},\n"
				result += "file: false\n"
				result += "}\n"
				result += "return @vars[:response]"
				return result
			when :!
				return "!(#{compile_command(command[1], true)})"
			else
				# Command might be a method call
				case command[0].to_s
				when "#"
					# It's a comment. Ignore this command
					return ""
				when "Session.get"
					return "_method_call('Session.get', access_token: #{compile_command(command[1], true)})"
				when "Table.get_table_objects"
					return "_method_call('Table.get_table_objects',
						id: #{compile_command(command[1], true)},
						user_id: #{compile_command(command[2], true)}
					)"
				when "TableObject.create"
					return "_method_call('TableObject.create',
						user_id: #{compile_command(command[1], true)},
						table_id: #{compile_command(command[2], true)},
						properties: #{compile_command(command[3], true)}
					)"
				when "Collection.add_table_object"
					return "_method_call('Collection.add_table_object',
						collection_name: #{compile_command(command[1], true)},
						table_object_id: #{compile_command(command[2], true)}
					)"
				end

				# Command might be an expression
				case command[1]
				when :==
					return "#{compile_command(command[0], true)} == #{compile_command(command[2], true)}"
				when :!=
					return "#{compile_command(command[0], true)} != #{compile_command(command[2], true)}"
				when :>
					return "#{compile_command(command[0], true)} > #{compile_command(command[2], true)}"
				when :<
					return "#{compile_command(command[0], true)} < #{compile_command(command[2], true)}"
				when :>=
					return "#{compile_command(command[0], true)} >= #{compile_command(command[2], true)}"
				when :<=
					return "#{compile_command(command[0], true)} <= #{compile_command(command[2], true)}"
				when :+, :-
					result = ""
					i = 1

					while !command[i].nil?
						if command[i] == :-
							result += "#{compile_command(command[0], true)} - #{compile_command(command[2], true)}"
						else
							result += "#{compile_command(command[0], true)} + #{compile_command(command[2], true)}"
						end

						i += 2
					end

					return result
				when :*
					return "#{compile_command(command[0], true)} * #{compile_command(command[2], true)}"
				when :/
					return "#{compile_command(command[0], true)} / #{compile_command(command[2], true)}"
				when :%
					return "#{compile_command(command[0], true)} % #{compile_command(command[2], true)}"
				when :and, :or
					result = ""
					i = 1

					while !command[i].nil?
						if command[i] == :and
							result += "#{compile_command(command[0], true)} && #{compile_command(command[2], true)}"
						else
							result += "#{compile_command(command[0], true)} || #{compile_command(command[2], true)}"
						end

						i += 2
					end

					return result
				end

				if command[0].to_s.include?('.')
					parts = command[0].to_s.split('.')
					function_name = parts.pop
					complete_command = ""

					valid = [
						"push",
						"contains",
						"join",
						"select",
						"split"
					].include?(function_name)

					if valid
						# Change the function name if necessary
						if function_name == "contains"
							complete_command = "#{compile_command(parts.join('.').to_sym, true)}.include?"
						elsif function_name == "select"
							return "#{parts.join('.')}[#{compile_command(command[1], true)}, #{compile_command(command[2], true)}]"
						else
							complete_command = "#{parts.join('.')}.#{function_name}"
						end

						# Get the parameters
						result = "#{complete_command}("

						i = 1
						while !command[i].nil?
							result += ", " if i != 1

							if command[i].is_a?(String)
								result += "\"#{command[i]}\""
							elsif command[i].is_a?(Array) && command[i].length == 1
								result += compile_command(command[i][0], true).to_s
							else
								result += compile_command(command[i], true).to_s
							end

							i += 1
						end

						result += ")"
						return result
					end

					return ""
				end
			end
		elsif command.is_a?(String)
			return "\"#{command}\""
		elsif command.is_a?(Float)
			return command
		elsif command.is_a?(NilClass)
			return "nil"
		elsif command.to_s.include?('..')
			parts = command.to_s.split('..')
			last_part = parts.pop

			# The first part of the command is probably a variable / hash
			return "#{compile_command(parts.join('..').to_sym, true)}[#{last_part}]"
		elsif command.to_s.include?('.')
			parts = command.to_s.split('.')
			last_part = parts.pop

			# Check if the last part is a method call
			valid = [
				"class",
				"length",
				"reverse",
				"upcase",
				"downcase",
				"to_i",
				"to_f",
				"round",
				"table_objects",
				"user_id",
				"app_id",
				"properties"
			].include?(last_part)

			if valid
				if last_part == "class"
					# Return the class as string
					return "#{command}.to_s"
				else
					return command
				end
			end

			# The first part of the command is probably a variable / hash
			return "#{compile_command(parts.join('.').to_sym, true)}[\"#{last_part}\"]"
		elsif command.to_s.include?('#')
			parts = command.to_s.split('#')
			last_part = parts.pop

			return "#{compile_command(parts.join('#').to_sym, true)}[#{last_part}]"
		else
			return command
		end
	end

	def compile_function_definition(function)
		result = "def #{function.name}("

		i = 0
		function.params.split(',').each do |parameter|
			result += ", " if i != 0
			result += parameter.to_s
			i += 1
		end

		result += ")\n"
		ast = @parser.parse_string(function.commands)

		ast.each do |element|
			result += "#{compile_command(element)}\n"
		end

		result += "end\n"
		return result
	end
end