require "test_helper"

class DavExpressionRunnerTest < ActiveSupport::TestCase
	setup do
		@runner = DavExpressionRunner.new
	end

	it "should be able to store and access variables" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var result "Hello World")
				(render_json result 200)
			'
		})

		assert_equal("Hello World", result[:data])
	end

	it "should correctly handle simple if expressions" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(if true (
					(render_json 1 200)
				) else (
					(render_json 2 200)
				))
			'
		})

		assert_equal(1, result[:data])
	end

	it "should correctly handle complex if expressions" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(if (1 == 2) (
					(render_json 1 200)
				) elseif (2 == 2) (
					(render_json 2 200)
				) else (
					(render_json 3 200)
				))
			'
		})

		assert_equal(2, result[:data])
	end

	it "should be able to run for each loops" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var numbers (list 1 2 3 4 5))
				(var result 0)

				(for n in numbers (
					(var result (result + n))
				))

				(render_json result 200)
			'
		})

		assert_equal(15, result[:data])
	end

	it "should be able to continue for each loops" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var numbers (list 1 2 3 4 5))
				(var result 0)

				(for n in numbers (
					(if (n >= 3) (continue))
					(var result (result + n))
				))

				(render_json result 200)
			'
		})

		assert_equal(3, result[:data])
	end

	it "should be able to break for each loops" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var numbers (list 1 2 3 4 5))
				(var result 0)

				(for n in numbers (
					(var result (result + n))

					(if (n >= 3) (break))
				))

				(render_json result 200)
			'
		})

		assert_equal(6, result[:data])
	end

	it "should be able to throw exceptions" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var result 0)

				(catch (
					(throw_errors 1 2 3)
				) (
					(for error in errors (
						(var result (result + error))
					))
				))

				(render_json result 200)
			'
		})

		assert_equal(6, result[:data])
	end

	it "should be able to throw exception within functions" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
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

				(render_json result 200)
			'
		})

		assert_equal(6, result[:data])
	end

	it "should be able to get the length of a string" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var string "Hello World")
				(render_json string.length 200)
			'
		})

		assert_equal(11, result[:data])
	end

	it "should be able to split a string" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var string "123.456.789")
				(render_json (string.split ".") 200)
			'
		})

		assert_equal("123", result[:data][0])
		assert_equal("456", result[:data][1])
		assert_equal("789", result[:data][2])
	end

	it "should be able to check if a string contains a substring" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var string "Hello World")
				(var result 0)

				(if (string.contains "Hello") (
					(var result (result + 1))
				))

				(if (string.contains "blabla") (
					(var result (result + 2))
				))

				(render_json result 200)
			'
		})

		assert_equal(1, result[:data])
	end

	it "should be able to convert a string to upcase and downcase" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var result (list))
				(var bla "bla")
				(var test "TEsT")

				(result.push (bla.upcase))
				(result.push (test.downcase))

				(render_json result 200)
			'
		})

		assert_equal("BLA", result[:data][0])
		assert_equal("test", result[:data][1])
	end

	it "should be able to convert a int to float" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var int 24)
				(render_json int.to_f 200)
			'
		})

		assert_equal(24.0, result[:data])
		assert_equal(Float, result[:data].class)
	end

	it "should be able to round a float" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var float 2.3523)
				(render_json float.round 200)
			'
		})

		assert_equal(2, result[:data])
	end

	it "should be able to create a hash and set and read values" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var hash (hash (test "Hello") (bla "World")))
				(var varname "test")
				(var result (list))

				(var hash.bla "World2")

				(result.push hash.test)
				(result.push hash.bla)
				(result.push hash..varname)

				(render_json result 200)
			'
		})

		assert_equal("Hello", result[:data][0])
		assert_equal("World2", result[:data][1])
		assert_equal("Hello", result[:data][2])
	end

	it "should be able to create a hash and set and read values using []" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var hash (hash (test "Hello") (bla "World")))
				(var varname "test")
				(var result (list))

				(var hash["bla"] "World2")

				(result.push hash["test"])
				(result.push hash["bla"])
				(result.push hash[varname])

				(render_json result 200)
			'
		})

		assert_equal("Hello", result[:data][0])
		assert_equal("World2", result[:data][1])
		assert_equal("Hello", result[:data][2])
	end

	it "should be able to use list" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var list (list 1 2 3))

				(list.push 4)

				(if (list.contains 1) (
					(list.push 5)
				))

				(list.pop)

				(var result 0)

				(for n in list (
					(var result (result + n))
				))

				(render_json result 200)
			'
		})

		assert_equal(10, result[:data])
	end

	it "should be able to use list within hash" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var hash (hash (root (list 1 2 3))))
				(var listname "root")

				(hash["root"].push 4)

				(if (hash["root"].contains 1) (
					(hash["root"].push 5)
				))

				(hash["root"].pop)

				(var result 0)

				(for n in hash[listname] (
					(var result (result + n))
				))

				(render_json result 200)
			'
		})

		assert_equal(10, result[:data])
	end

	it "should be able to use advanced methods on list" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
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

				(render_json result 200)
			'
		})

		assert_equal(true, result[:data][0])
		assert_equal(false, result[:data][1])
		assert_equal("ipsum", result[:data][2][0])
		assert_equal("dolor", result[:data][2][1])
		assert_equal("sit", result[:data][2][2])
		assert_equal("Lorem ipsum dolor sit amet", result[:data][3])
		assert_equal("dolor", result[:data][4])
		assert_equal("dolor", result[:data][5])
		assert_equal(5, result[:data][6])
		assert_equal("amet.sit.dolor.ipsum.Lorem", result[:data][7])
	end

	it "should be able to define and call functions" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(def add (a b) (
					(return (a + b))
				))

				(var result (func add (42 74)))

				(render_json result 200)
			'
		})

		assert_equal(116, result[:data])
	end

	test "to_int should return the given value as int" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var result "42")
				(render_json (to_int result) 200)
			'
		})

		assert_equal(42, result[:data])
	end

	test "is_nil should return true if the given value is nil" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
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

				(render_json result 200)
			'
		})

		assert_equal(1, result[:data])
	end

	test "class should return the class of the variable" do
		result = @runner.run({
			api_slot: api_slots(:pocketlibApiMaster),
			vars: Hash.new,
			commands: '
				(var result (list))

				(var string "Hello")
				(result.push string.class)

				(var int 23)
				(result.push int.class)

				(var float 12.34)
				(result.push float.class)

				(render_json result 200)
			'
		})

		assert_equal("String", result[:data][0])
		assert_equal("Integer", result[:data][1])
		assert_equal("Float", result[:data][2])
	end
end
