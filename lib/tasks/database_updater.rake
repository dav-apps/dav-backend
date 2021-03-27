namespace :database_updater do
	task update_used_storage_of_users: :environment do
		# Update used_storage fields of each user
		User.all.each do |user|
			used_storage = 0
			
			user.table_objects.where(file: true).each do |obj|
				used_storage += get_file_size_of_table_object(obj)
			end

			user.used_storage = used_storage
			user.save
		end
	end

	task update_used_storage_of_app_users: :environment do
		AppUser.all.each do |app_user|
			used_storage = 0

			app_user.app.tables.each do |table|
				table.table_objects.where(user: app_user.user, file: true).each do |obj|
					used_storage += get_file_size_of_table_object(obj)
				end
			end

			app_user.used_storage = used_storage
			app_user.save
		end
	end

	private
	def get_file_size_of_table_object(obj)
		size_prop = obj.table_object_properties.find_by(name: "size")
		size_prop.nil? ? 0 : size_prop.value.to_i
	end
end