class BlobOperationsService
	def self.upload_blob(table_object_id, app_id, blob)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		# Read the file
		contents = blob.class == StringIO ? blob.read : File.open(blob, "rb")

		client.create_block_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{app_id}/#{table_object_id}",
			contents
		)
	rescue
	end

	def self.download_blob(table_object_id, app_id)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.get_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{app_id}/#{table_object_id}"
		)

		# {
		# 	blob: blob,
		# 	content: content
		# }
	rescue
	end

	def self.delete_blob(app_id, object_id)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.delete_blob(
			ENV['AZURE_FILES_CONTAINER_NAME'],
			"#{app_id}/#{object_id}"
		)
	rescue
	end
end