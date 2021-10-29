require "test_helper"

class DavExpressionCompilerTest < ActiveSupport::TestCase
	setup do
		@compiler = DavExpressionCompiler.new
	end

	it "should be able to store and access variables" do
		code = @compiler.compile({
			commands: '
				(var result "Hello World")
				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal("Hello World", result)
	end

	it "should correctly handle simple if expressions" do
		code = @compiler.compile({
			commands: '
				(if true (
					(return 1)
				) else (
					(return 2)
				))
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(1, result)
	end

	it "should correctly handle complex if expressions" do
		code = @compiler.compile({
			commands: '
				(if (1 == 2) (
					(return 1)
				) elseif (2 == 2) (
					(return 2)
				) else (
					(return 3)
				))
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(2, result)
	end

	it "should be able to run for each loops" do
		code = @compiler.compile({
			commands: '
				(var numbers (list 1 2 3 4 5))
				(var result 0)

				(for n in numbers (
					(var result (result + n))
				))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(15, result)
	end

	it "should be able to break for each loops" do
		code = @compiler.compile({
			commands: '
				(var numbers (list 1 2 3 4 5))
				(var result 0)

				(for n in numbers (
					(var result (result + n))

					(if (n >= 3) (break))
				))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(6, result)
	end

	it "should be able to throw exceptions" do
		code = @compiler.compile({
			commands: '
				(var result 0)

				(catch (
					(throw_errors 1 2 3)
				) (
					(for error in errors (
						(var result (result + error))
					))
				))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(6, result)
	end

	it "should be able to throw exception within functions" do
		code = @compiler.compile({
			commands: '
				(def add (a b) (
					(if ((a < 0) or (b < 0)) (
						(throw_errors 1 2 3)
					))

					(return (a + b))
				))

				(var result 0)

				(catch (
					(func add (5 -1))
				) (
					(for error in errors (
						(var result (result + error))
					))
				))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(6, result)
	end

	it "should be able to get the length of a string" do
		code = @compiler.compile({
			commands: '
				(var string "Hello World")
				(return string.length)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(11, result)
	end

	it "should be able to split a string" do
		code = @compiler.compile({
			commands: '
				(var string "123.456.789")
				(return (string.split "."))
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal("123", result[0])
		assert_equal("456", result[1])
		assert_equal("789", result[2])
	end

	it "should be able to check if a string contains a substring" do
		code = @compiler.compile({
			commands: '
				(var string "Hello World")
				(var result 0)

				(if (string.contains "Hello") (
					(var result (result + 1))
				))

				(if (string.contains "blabla") (
					(var result (result + 2))
				))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(1, result)
	end

	it "should be able to convert a string to upcase and downcase" do
		code = @compiler.compile({
			commands: '
				(var result (list))
				(var bla "bla")
				(var test "TEsT")

				(result.push (bla.upcase))
				(result.push (test.downcase))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal("BLA", result[0])
		assert_equal("test", result[1])
	end

	it "should be able to convert a int to float" do
		code = @compiler.compile({
			commands: '
				(var int 24)
				(return int.to_f)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(24.0, result)
		assert_equal(Float, result.class)
	end

	it "should be able to round a float" do
		code = @compiler.compile({
			commands: '
				(var float 2.3523)
				(return float.round)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(2, result)
	end

	it "should be able to create a hash and set and read values" do
		code = @compiler.compile({
			commands: '
				(var hash (hash (test "Hello") (bla "World")))
				(var varname "test")
				(var result (list))

				(var hash.bla "World2")

				(result.push hash.test)
				(result.push hash.bla)
				(result.push hash..varname)

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal("Hello", result[0])
		assert_equal("World2", result[1])
		assert_equal("Hello", result[2])
	end

	it "should be able to create and fill a list" do
		code = @compiler.compile({
			commands: '
				(var list (list 1 2))

				(list.push 3)

				(if (list.contains 1) (
					(list.push 4)
				))

				(var result 0)

				(for n in list (
					(var result (result + n))
				))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(10, result)
	end

	it "should be able to use advanced methods on list" do
		code = @compiler.compile({
			commands: '
				(var list (list "Lorem" "ipsum" "dolor" "sit" "amet"))
				(var result (list))

				(# contains)
				(result.push (list.contains "ipsum"))
				(result.push (list.contains "bla"))

				(# select)
				(result.push (list.select 1 3))

				(# join)
				(result.push (list.join " "))

				(# Read value on position)
				(var pos 2)
				(result.push (list#2))
				(result.push (list#pos))

				(# length)
				(result.push (list.length))

				(# reverse)
				(var list2 list.reverse)
				(result.push (list2.join "."))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(true, result[0])
		assert_equal(false, result[1])
		assert_equal("ipsum", result[2][0])
		assert_equal("dolor", result[2][1])
		assert_equal("sit", result[2][2])
		assert_equal("Lorem ipsum dolor sit amet", result[3])
		assert_equal("dolor", result[4])
		assert_equal("dolor", result[5])
		assert_equal(5, result[6])
		assert_equal("amet.sit.dolor.ipsum.Lorem", result[7])
	end

	it "should be able to define and call functions" do
		code = @compiler.compile({
			commands: '
				(def add (a b) (
					(return (a + b))
				))

				(var result (func add (42 74)))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(116, result)
	end

	test "to_int should return the given value as int" do
		code = @compiler.compile({
			commands: '
				(var result "42")
				(return (to_int result))
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(42, result)
	end

	test "is_nil should return true if the given value is nil" do
		code = @compiler.compile({
			commands: '
				(var test nil)
				(var test2 23)
				(var result 0)

				(if (is_nil test) (
					(var result (result + 1))
				))

				(if (is_nil test2) (
					(var result (result + 2))
				))

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal(1, result)
	end

	test "class should return the class of the variable" do
		code = @compiler.compile({
			commands: '
				(var result (list))

				(var string "Hello")
				(result.push string.class)

				(var int 23)
				(result.push int.class)

				(var float 12.34)
				(result.push float.class)

				(return result)
			'
		})

		result = @compiler.run({
			code: code,
			api: apis(:pocketlibApi)
		})

		assert_equal("String", result[0])
		assert_equal("Integer", result[1])
		assert_equal("Float", result[2])
	end
end