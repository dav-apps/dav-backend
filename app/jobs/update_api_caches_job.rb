class UpdateApiCachesJob < ApplicationJob
	queue_as :default

	def perform(*args)
		# Go through all changes in the database
		TableObjectChange.all.each do |obj_change|
			# Find the corresponding ApiEndpointRequestCacheDependencies
			# Look for each combination of ids
			ApiEndpointRequestCacheDependency
				.where("user_id = ? OR table_id = ? OR table_object_id = ? OR collection_id = ?", obj_change.user_id, obj_change.table_id, obj_change.table_object_id, obj_change.collection_id)
				.each { |dependency| set_api_endpoint_request_cache_as_old(dependency.api_endpoint_request_cache) }

			if !obj_change.table_object.nil?
				# Look for the user the table object belongs to
				ApiEndpointRequestCacheDependency.where(user: obj_change.table_object.user).each do |dependency|
					set_api_endpoint_request_cache_as_old(dependency.api_endpoint_request_cache)
				end

				# Look for each table the table object belongs to
				ApiEndpointRequestCacheDependency.where(table: obj_change.table_object.table).each do |dependency|
					set_api_endpoint_request_cache_as_old(dependency.api_endpoint_request_cache)
				end

				# Look for each collection the table object belongs to
				obj_change.table_object.collections.each do |collection|
					ApiEndpointRequestCacheDependency.where(collection: collection).each do |dependency|
						set_api_endpoint_request_cache_as_old(dependency.api_endpoint_request_cache)
					end
				end
			end

			obj_change.destroy!
		end

		if ENV["USE_COMPILED_API_ENDPOINTS"] == "true" && !Rails.env.test?
			compiler = DavExpressionCompiler.new

			ApiEndpoint.where(caching: true).each do |api_endpoint|
				api_slot = api_endpoint.api_slot

				# Get the compiled endpoint
				compiled_endpoint = api_endpoint.compiled_api_endpoint
				next if compiled_endpoint.nil?

				api_endpoint.api_endpoint_request_caches.where(old: true).each do |cache|
					# Get the params
					url_params = Hash.new
					cache.api_endpoint_request_cache_params.each do |param|
						url_params[param.name] = param.value
					end

					result = compiler.run({
						code: compiled_endpoint.code,
						api_slot: api_slot,
						request: {
							headers: Hash.new,
							params: url_params,
							body: nil
						}
					})

					if result[:status] == 200 && !result[:file]
						# Update the cache
						cache.response = result[:data].to_json
						cache.old = false
						cache.save
					end

					# Save the new dependencies in the database
					old_dependencies = cache.api_endpoint_request_cache_dependencies
					new_dependencies = result[:dependencies]

					# Remove all old dependencies and save all new dependencies
					old_dependencies.each { |dependency| dependency.destroy! }

					new_dependencies.each do |dependency|
						ApiEndpointRequestCacheDependency.create(
							user_id: dependency[:user_id],
							table_id: dependency[:table_id],
							table_object_id: dependency[:table_object_id],
							collection_id: dependency[:collection_id],
							api_endpoint_request_cache: cache,
							name: dependency[:name]
						)
					end
				end
			end
		else
			runner = DavExpressionRunner.new

			ApiEndpoint.where(caching: true).each do |api_endpoint|
				api_slot = api_endpoint.api_slot

				api_endpoint.api_endpoint_request_caches.where(old: true).each do |cache|
					vars = Hash.new
					url_params = Hash.new

					# Get the environment variables of the api
					env_vars = Hash.new
					api_slot.api_env_vars.each do |env_var|
						env_vars[env_var.name] = UtilsService.convert_env_value(env_var.class_name, env_var.value)
					end

					vars["env"] = env_vars

					# Get the params
					cache.api_endpoint_request_cache_params.each do |param|
						url_params[param.name] = param.value
					end

					result = runner.run({
						api_slot: api_slot,
						vars: vars,
						commands: api_endpoint.commands,
						request: {
							headers: Hash.new,
							params: url_params,
							body: nil
						}
					})

					if result[:status] == 200 && !result[:file]
						# Update the cache
						cache.response = result[:data].to_json
						cache.old = false
						cache.save
					end

					# Save the new dependencies in the database
					old_dependencies = cache.api_endpoint_request_cache_dependencies
					new_dependencies = result[:dependencies]

					# Remove all old dependencies and save all new dependencies
					old_dependencies.each { |dependency| dependency.destroy! }

					new_dependencies.each do |dependency|
						ApiEndpointRequestCacheDependency.create(
							user_id: dependency[:user_id],
							table_id: dependency[:table_id],
							table_object_id: dependency[:table_object_id],
							collection_id: dependency[:collection_id],
							api_endpoint_request_cache: cache,
							name: dependency[:name]
						)
					end
				end
			end
		end
	end

	private
	def set_api_endpoint_request_cache_as_old(cache)
		return if cache.old

		cache.old = true
		cache.save
	end
end
