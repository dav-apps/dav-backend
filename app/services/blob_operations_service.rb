class BlobOperationsService
	def self.upload_blob(table_object, blob, content_type)
		# Read the file
		contents = blob.class == StringIO ? blob.string : File.open(blob, "rb").read

		UtilsService.s3.put_object({
			bucket: ENV["SPACE_NAME"],
			key: table_object.uuid,
			body: contents,
			acl: table_object.table.cdn ? "public-read" : "private",
			content_type: content_type
		})
	end

	def self.download_blob(table_object)
		begin
			tempfile = Tempfile.new

			result = UtilsService.s3.get_object(
				bucket: ENV["SPACE_NAME"],
				key: table_object.uuid,
				response_target: tempfile.path
			)

			return result, File.open(tempfile.path, "rb").read
		rescue => e
			begin
				client = Azure::Storage::Blob::BlobService.create(
					storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
					storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
				)
		
				client.get_blob(
					ENV['AZURE_FILES_CONTAINER_NAME'],
					"#{table_object.table.app.id}/#{table_object.id}"
				)
			rescue => e2
			end
		end

		return nil
	end

	def self.delete_blob(table_object)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.delete_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{table_object.table.app.id}/#{table_object.id}"
		)

		UtilsService.s3.delete_object({
			bucket: ENV["SPACE_NAME"],
			key: table_object.uuid
		})
	rescue => e
	end

	def self.upload_profile_image(user, blob, content_type)
		# Read the file
		contents = blob.class == StringIO ? blob.string : File.open(blob, "rb").read

		UtilsService.s3.put_object({
			bucket: ENV["SPACE_NAME"],
			key: "profileImages/#{user.id}",
			body: contents,
			acl: "public-read",
			content_type: content_type
		})
	end

	def self.download_profile_image(user)
		begin
			tempfile = Tempfile.new

			result = UtilsService.s3.get_object(
				bucket: ENV["SPACE_NAME"],
				key: "profileImages/#{user.id}",
				response_target: tempfile.path
			)

			return result, File.open(tempfile.path, "rb").read
		rescue => e
			client = Azure::Storage::Blob::BlobService.create(
				storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
				storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
			)
	
			client.get_blob(
				ENV['AZURE_AVATAR_CONTAINER_NAME'],
				"#{user.id}.png"
			)
		end

		return nil
	end

	def self.download_default_profile_image
		tempfile = Tempfile.new

		result = UtilsService.s3.get_object(
			bucket: ENV["SPACE_NAME"],
			key: "profileImages/default.png",
			response_target: tempfile.path
		)

		return result, File.open(tempfile.path, "rb").read
	end
end