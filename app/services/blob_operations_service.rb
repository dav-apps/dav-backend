class BlobOperationsService
	def self.upload_blob(table_object, blob)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		# Read the file
		contents = blob.class == StringIO ? blob.read : File.open(blob, "rb")

		client.create_block_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{table_object.table.app.id}/#{table_object.id}",
			contents
		)
	end

	def self.download_blob(table_object)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.get_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{table_object.table.app.id}/#{table_object.id}"
		)
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
	end

	def self.upload_profile_image(user, blob)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		# Read the file
		contents = blob.class == StringIO ? blob.read : File.open(blob, "rb")

		client.create_block_blob(
			ENV["AZURE_AVATAR_CONTAINER_NAME"],
			"#{user.id}.png",
			contents
		)
	end

	def self.download_profile_image(user)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.get_blob(
			ENV['AZURE_AVATAR_CONTAINER_NAME'],
			"#{user.id}.png"
		)
	end

	def self.download_default_profile_image
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.get_blob(
			ENV['AZURE_AVATAR_CONTAINER_NAME'],
			"default.png"
		)
	end
end