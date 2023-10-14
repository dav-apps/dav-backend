class CollectionsController < ApplicationController
	def set_table_objects_of_collection
		auth = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		table_id = body["table_id"]
		name = body["name"]
		table_object_uuids = body["table_objects"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_table_id_presence(table_id),
			ValidationService.validate_name_presence(name),
			ValidationService.validate_table_objects_presence(table_object_uuids)
		])

		# Validate the types of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_table_id_type(table_id),
			ValidationService.validate_name_type(name),
			ValidationService.validate_table_objects_type(table_object_uuids)
		])

		# Get the table
		table = Table.find_by(id: table_id)
		ValidationService.raise_validation_errors(ValidationService.validate_table_existence(table))

		# Check if the app of the table belongs to the dev
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(table.app, dev))

		# Get the collection
		collection = Collection.find_by(table: table, name: name)
		ValidationService.raise_validation_errors(ValidationService.validate_collection_existence(collection))

		table_objects = Array.new
		table_object_uuids.each do |uuid|
			# Get the table object
			table_object = TableObject.find_by(uuid: uuid)
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))

			# Check if the table object belongs to the table of the collection
			ValidationService.raise_validation_errors(ValidationService.validate_table_object_belongs_to_table(table_object, collection.table))

			table_objects.push(table_object)
		end

		# Remove all table objects from the collection
		collection.table_object_collections.each do |obj_col|
			obj_col.destroy!
		end

		# Add each table object to the collection
		table_objects.each do |obj|
			obj_col = TableObjectCollection.new(table_object: obj, collection: collection)
			ValidationService.raise_unexpected_error(!obj_col.save)
		end

		# Return the collection
		result = {
			id: collection.id,
			table_id: collection.table_id,
			name: collection.name
		}
		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	# v2
	def add_table_object_to_collection
		auth = get_auth
		name = params[:name]
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Get the body params
		body = ValidationService.parse_json(request.body.string)
		table_id = body["table_id"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_table_id_presence(table_id)
		])

		# Validate field types
		ValidationService.raise_validation_errors([
			ValidationService.validate_table_id_type(table_id)
		])

		# Get the table
		table = Table.find_by(id: table_id)
		ValidationService.raise_validation_errors(ValidationService.validate_table_existence(table))

		# Check if the app of the table belongs to the dev
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(table.app, dev))

		# Get the collection
		collection = Collection.find_by(table: table, name: name)
		ValidationService.raise_validation_errors(ValidationService.validate_collection_existence(collection))

		# Get the table object
		table_object = TableObject.find_by(uuid: uuid)
		ValidationService.raise_validation_errors(ValidationService.validate_table_object_existence(table_object))

		# Check if the table object already belongs to the collection
		obj_col = TableObjectCollection.find_by(table_object: table_object, collection: collection)

		if obj_col.nil?
			# Add the table object to the collection
			obj_col = TableObjectCollection.new(table_object: table_object, collection: collection)
			ValidationService.raise_unexpected_error(!obj_col.save)
		end

		# Return the collection
		result = {
			id: collection.id,
			table_id: collection.table_id,
			name: collection.name
		}

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end
