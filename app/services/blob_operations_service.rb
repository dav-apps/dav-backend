class BlobOperationsService
	def self.delete_blob(app_id, object_id)
		client = Azure::Storage::Blob::BlobService.create(
			storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
			storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
		)

		client.delete_blob(ENV['AZURE_FILES_CONTAINER_NAME'], "#{app_id}/#{object_id}")
	rescue
	end
end