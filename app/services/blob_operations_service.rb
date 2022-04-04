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
		tempfile = Tempfile.new

		result = UtilsService.s3.get_object(
			bucket: ENV["SPACE_NAME"],
			key: table_object.uuid,
			response_target: tempfile.path
		)

		return result, File.open(tempfile.path, "rb").read
	end

	def self.delete_blob(table_object)
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
		tempfile = Tempfile.new

		result = UtilsService.s3.get_object(
			bucket: ENV["SPACE_NAME"],
			key: "profileImages/#{user.id}",
			response_target: tempfile.path
		)

		return result, File.open(tempfile.path, "rb").read
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