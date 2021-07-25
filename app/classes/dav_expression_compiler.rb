class DavExpressionCompiler
	def compile(props)
		@api = props[:api]
		@vars = props[:vars]
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

		# Define functions at the beginning of the code
		functions_code = ""
		@functions_to_define.each do |function|
			functions_code += compile_function_definition(function)
		end

		return functions_code + code
	end

	private
	def compile_command(command)
		if command.class == Array
			if command[0].class == Array && (!command[1] || command[1].class == Array)
				# Command contains commands
				code = ""
				command.each do |c|
					code += "#{compile_command(c)}\n"
				end
				return code
			end

			# Command is a function call
			case command[0]
			when :var
				if command[1].to_s.include?('..')
					parts = command[1].to_s.split('..')
					last_part = parts.pop

					return "#{compile_command(parts.join('..').to_sym)}[\"#{last_part}\"] = #{compile_command(command[2])}"
				elsif command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop

					return "#{compile_command(parts.join('.').to_sym)}[\"#{last_part}\"] = #{compile_command(command[2])}"
				else
					return "#{command[1]} = #{compile_command(command[2])}"
				end
			when :return
				return "return #{compile_command(command[1])}"
			when :hash
				result = "{\n"
				i = 1

				while !command[i].nil? && command[i].is_a?(Array)
					result += "\"#{command[i][0]}\" => #{compile_command(command[i][1])},\n"
					i += 1
				end

				result += "}\n"
				return result
			when :list
				result = "[\n"
				i = 1

				while !command[i].nil?
					result += "#{compile_command(command[i])},\n"
					i += 1
				end

				result += "]\n"
				return result
			when :if
				result = "if (#{compile_command(command[1])})\n"
				result += "#{compile_command(command[2])}\n"

				i = 3
				while !command[i].nil?
					if command[i] == :elseif
						result += "elsif #{compile_command(command[i + 1])}\n"
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

				result = "#{command[3]}.each do |#{command[1]}|\n"
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
					result += parameter.to_s
					i += 1
				end

				result += ")\n"
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
					errors += "#{compile_command(command[i])},\n"
					i += 1
				end

				errors += "].to_json"
				return "raise RuntimeError, #{errors}"
			when :log
				return "puts #{compile_command(command[1])}"
			when :to_int
				return "#{command[1]}.to_i"
			when :is_nil
				return "#{compile_command(command[1])}.nil?"
			else
				# Command might be a method call
				case command[0].to_s
				when "#"
					# It's a comment. Ignore this command
					return ""
				end

				# Command might be an expression
				case command[1]
				when :==
					return "#{compile_command(command[0])} == #{compile_command(command[2])}"
				when :!=
					return "#{compile_command(command[0])} != #{compile_command(command[2])}"
				when :>
					return "#{compile_command(command[0])} > #{compile_command(command[2])}"
				when :<
					return "#{compile_command(command[0])} < #{compile_command(command[2])}"
				when :>=
					return "#{compile_command(command[0])} >= #{compile_command(command[2])}"
				when :<=
					return "#{compile_command(command[0])} <= #{compile_command(command[2])}"
				when :+, :-
					result = ""
					i = 1

					while !command[i].nil?
						if command[i] == :-
							result += "#{compile_command(command[0])} - #{compile_command(command[2])}"
						else
							result += "#{compile_command(command[0])} + #{compile_command(command[2])}"
						end

						i += 2
					end

					return result
				when :*
					return "#{compile_command(command[0])} * #{compile_command(command[2])}"
				when :/
					return "#{compile_command(command[0])} / #{compile_command(command[2])}"
				when :%
					return "#{compile_command(command[0])} % #{compile_command(command[2])}"
				when :and, :or
					result = ""
					i = 1

					while !command[i].nil?
						if command[i] == :and
							result += "#{compile_command(command[0])} && #{compile_command(command[2])}"
						else
							result += "#{compile_command(command[0])} || #{compile_command(command[2])}"
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
							complete_command = "#{parts.join('.')}.include?"
						elsif function_name == "select"
							return "#{parts.join('.')}[#{compile_command(command[1])}, #{compile_command(command[2])}]"
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
								result += compile_command(command[i][0]).to_s
							else
								result += compile_command(command[i]).to_s
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
		elsif command.to_s.include?('#')
			parts = command.to_s.split('#')
			last_part = parts.pop

			return "#{compile_command(parts.join('#').to_sym)}[#{last_part}]"
		elsif command.to_s.include?('..')
			parts = command.to_s.split('..')
			last_part = parts.pop

			# The first part of the command is probably a variable / hash
			return "#{compile_command(parts.join('..').to_sym)}[#{last_part}]"
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

			return command if valid
			
			# The first part of the command is probably a variable / hash
			return "#{compile_command(parts.join('.').to_sym)}[\"#{last_part}\"]"
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