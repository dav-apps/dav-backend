class BlobOperationsService
	def self.upload_blob(table_object, blob, content_type)
		# Read the file
		contents = blob.class == StringIO ? blob.string : File.open(blob, "rb").read

		UtilsService.s3.put_object({
			bucket: ENV["BUCKET_NAME_WRITE"],
			key: table_object.uuid,
			body: contents,
			acl: table_object.table.cdn ? "public-read" : "private",
			content_type: content_type
		})
	end

	def self.download_blob(table_object)
		tempfile = Tempfile.new

		begin
			# Try to get the file from the write bucket
			return get_file(
				ENV["BUCKET_NAME_WRITE"],
				table_object.uuid,
				tempfile
			)
		rescue => e
		end

		begin
			# Try to get the file from the read bucket
			return get_file(
				ENV["BUCKET_NAME_READ"],
				table_object.uuid,
				tempfile
			)
		rescue => e
			raise e
		end
	end

	def self.delete_blob(table_object)
		UtilsService.s3.delete_object({
			bucket: ENV["BUCKET_NAME_WRITE"],
			key: table_object.uuid
		})
	rescue => e
	end

	def self.upload_profile_image(user, blob, content_type)
		# Read the file
		contents = blob.class == StringIO ? blob.string : File.open(blob, "rb").read

		UtilsService.s3.put_object({
			bucket: ENV["BUCKET_NAME_WRITE"],
			key: "profileImages/#{user.id}",
			body: contents,
			acl: "public-read",
			content_type: content_type
		})
	end

	def self.download_profile_image(user)
		tempfile = Tempfile.new

		begin
			# Try to get the file from the write bucket
			return get_file(
				ENV["BUCKET_NAME_WRITE"],
				"profileImages/#{user.id}",
				tempfile
			)
		rescue => e
		end

		begin
			return get_file(
				ENV["BUCKET_NAME_READ"],
				"profileImages/#{user.id}",
				tempfile
			)
		rescue => e
			raise e
		end
	end

	def self.download_default_profile_image
		tempfile = Tempfile.new

		return get_file(
			ENV["BUCKET_NAME_READ"],
			"profileImages/default.png",
			tempfile
		)
	end

	private
	def self.get_file(bucket, key, tempfile)
		result = UtilsService.s3.get_object(
			bucket: bucket,
			key: key,
			response_target: tempfile.path
		)

		return result, File.open(tempfile.path, "rb").read
	end
end