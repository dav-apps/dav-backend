class ValidationService
	# Generic request errors
	def self.raise_unexpected_error(raise_error = true)
		if raise_error
			error_code = 1000
			raise RuntimeError, [get_validation_hash(error_code, 500)].to_json
		end
	end

	def self.validate_auth(auth)
		error_code = 1001
		return get_validation_hash(2101, 401) if !auth

		api_key, signature = auth.split(',')
		dev = Dev.find_by(api_key: api_key)
		return get_validation_hash(error_code, 401) if !dev

		# Check the signature
		sig = Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
		sig != signature ? get_validation_hash(error_code, 401) : get_validation_hash
	end

	def self.validate_dev_is_first_dev(dev)
		error_code = 1002
		dev != Dev.first ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_app_is_dav_app(app)
		error_code = 1002
		app.id != ENV["DAV_APPS_APP_ID"].to_i ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_app_belongs_to_dev(app, dev)
		error_code = 1002
		(app.nil? || dev.nil? || app.dev != dev) ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_table_belongs_to_app(table, app)
		error_code = 1002
		table.app != app ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_table_object_belongs_to_user(table_object, user)
		error_code = 1002
		table_object.user != user ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_table_object_belongs_to_app(table_object, app)
		error_code = 1002
		table_object.table.app != app ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_table_object_belongs_to_table(table_object, table)
		error_code = 1002
		table_object.table != table ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_purchase_belongs_to_user(purchase, user)
		error_code = 1002
		purchase.user != user ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_purchase_belongs_to_app(purchase, app)
		error_code = 1002
		purchase.table_objects.first.table.app != app ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_web_push_subscription_belongs_to_session(web_push_subscription, session)
		error_code = 1002
		web_push_subscription.session != session ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_notification_belongs_to_user(notification, user)
		error_code = 1002
		notification.user != user ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	def self.validate_notification_belongs_to_app(notification, app)
		error_code = 1002
		notification.app != app ? get_validation_hash(error_code, 403) : get_validation_hash
	end

	# Errors for missing headers
	def self.validate_auth_header_presence(auth)
		error_code = 1100
		auth.nil? ? get_validation_hash(error_code, 401) : get_validation_hash
	end

	def self.validate_content_type_json(content_type)
		return get_validation_hash(1101, 400) if content_type.nil?
		return get_validation_hash(1003, 415) if !content_type.include?("application/json")
		get_validation_hash
	end

	def self.validate_content_type_image(content_type)
		return get_validation_hash(1101, 400) if content_type.nil?
		return get_validation_hash(1003, 415) if !content_type.include?("image/png") && !content_type.include?("image/jpeg")
		get_validation_hash
	end

	def self.validate_content_type_supported(content_type)
		return get_validation_hash(1101, 400) if content_type.nil?
		return get_validation_hash(1003, 415) if content_type.include?("application/x-www-form-urlencoded")
		get_validation_hash
	end

	# File errors
	def self.validate_content_type_matches_file_type(content_type, file_type)
		error_code = 1200
		!content_type.include?(file_type) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.raise_image_file_invalid
		raise RuntimeError, [get_validation_hash(1201, 400)].to_json
	end

	def self.validate_image_size(size)
		error_code = 1202
		size > (Rails.env.test? ? 1000 : 2000000) ? get_validation_hash(error_code, 400): get_validation_hash
	end

	# Generic request body errors
	def self.parse_json(json)
		json && json.length > 0 ? JSON.parse(json) : Hash.new
	rescue JSON::ParserError => e
		# Raise error for invalid body
		error_code = 2000
		raise RuntimeError, [get_validation_hash(error_code, 400)].to_json
	end

	def self.validate_table_objects_count(table_objects)
		error_code = 2001
		table_objects.count == 0 ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	# Missing fields
	def self.validate_access_token_presence(access_token)
		error_code = 2100
		access_token.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_app_id_presence(app_id)
		error_code = 2101
		app_id.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_table_id_presence(table_id)
		error_code = 2102
		table_id.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_email_presence(email)
		error_code = 2103
		email.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_first_name_presence(first_name)
		error_code = 2104
		first_name.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_password_presence(password)
		error_code = 2105
		password.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_email_confirmation_token_presence(email_confirmation_token)
		error_code = 2106
		email_confirmation_token.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_password_confirmation_token_presence(password_confirmation_token)
		error_code = 2107
		password_confirmation_token.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_country_presence(country)
		error_code = 2108
		country.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_api_key_presence(api_key)
		error_code = 2109
		api_key.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_name_presence(name)
		error_code = 2110
		name.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_description_presence(description)
		error_code = 2111
		description.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_properties_presence(properties)
		error_code = 2112
		properties.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_product_name_presence(product_name)
		error_code = 2115
		product_name.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_product_image_presence(product_image)
		error_code = 2116
		product_image.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_currency_presence(currency)
		error_code = 2117
		currency.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_endpoint_presence(endpoint)
		error_code = 2118
		endpoint.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_p256dh_presence(p256dh)
		error_code = 2119
		p256dh.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_auth_presence(auth)
		error_code = 2120
		auth.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_time_presence(time)
		error_code = 2121
		time.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_interval_presence(interval)
		error_code = 2122
		interval.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_title_presence(title)
		error_code = 2123
		title.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_body_presence(body)
		error_code = 2124
		body.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_path_presence(path)
		error_code = 2125
		path.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_method_presence(method)
		error_code = 2126
		method.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_commands_presence(commands)
		error_code = 2127
		commands.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_errors_presence(errors)
		error_code = 2128
		errors.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_env_vars_presence(env_vars)
		error_code = 2129
		env_vars.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_table_objects_presence(table_objects)
		error_code = 2130
		table_objects.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_slot_presence(slot)
		error_code = 2131
		slot.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_plan_presence(plan)
		error_code = 2132
		plan.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_success_url_presence(success_url)
		error_code = 2133
		success_url.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_cancel_url_presence(cancel_url)
		error_code = 2134
		cancel_url.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_price_presence(price)
		error_code = 2135
		price.nil? ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	# Fields with wrong type
	def self.validate_access_token_type(access_token)
		error_code = 2200
		!access_token.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_uuid_type(uuid)
		error_code = 2201
		!uuid.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_app_id_type(app_id)
		error_code = 2202
		!app_id.is_a?(Integer) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_table_id_type(table_id)
		error_code = 2203
		!table_id.is_a?(Integer) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_email_type(email)
		error_code = 2204
		!email.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_first_name_type(first_name)
		error_code = 2205
		!first_name.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_password_type(password)
		error_code = 2206
		!password.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_email_confirmation_token_type(email_confirmation_token)
		error_code = 2207
		!email_confirmation_token.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_password_confirmation_token_type(password_confirmation_token)
		error_code = 2208
		!password_confirmation_token.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_country_type(country)
		error_code = 2209
		!country.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_api_key_type(api_key)
		error_code = 2210
		!api_key.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_device_name_type(device_name)
		error_code = 2211
		!device_name.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_device_os_type(device_os)
		error_code = 2213
		!device_os.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_name_type(name)
		error_code = 2214
		!name.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_description_type(description)
		error_code = 2215
		!description.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_published_type(published)
		error_code = 2216
		(!published.is_a?(TrueClass) && !published.is_a?(FalseClass)) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_web_link_type(web_link)
		error_code = 2217
		!web_link.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_google_play_link_type(google_play_link)
		error_code = 2218
		!google_play_link.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_microsoft_store_link_type(microsoft_store_link)
		error_code = 2219
		!microsoft_store_link.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_file_type(file)
		error_code = 2220
		(!file.is_a?(TrueClass) && !file.is_a?(FalseClass)) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_properties_type(properties)
		error_code = 2221
		!properties.is_a?(Hash) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_property_name_type(name)
		error_code = 2222
		!name.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_property_value_type(value)
		error_code = 2223
		return get_validation_hash if value.is_a?(NilClass)
		return get_validation_hash if value.is_a?(TrueClass)
		return get_validation_hash if value.is_a?(FalseClass)
		return get_validation_hash if value.is_a?(String)
		return get_validation_hash if value.is_a?(Integer)
		return get_validation_hash if value.is_a?(Float)
		get_validation_hash(error_code, 400)
	end

	def self.validate_ext_type(ext)
		error_code = 2224
		!ext.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_product_name_type(product_name)
		error_code = 2227
		!product_name.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_product_image_type(product_image)
		error_code = 2228
		!product_image.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_currency_type(currency)
		error_code = 2229
		!currency.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_endpoint_type(endpoint)
		error_code = 2230
		!endpoint.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_p256dh_type(p256dh)
		error_code = 2231
		!p256dh.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_auth_type(auth)
		error_code = 2232
		!auth.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_time_type(time)
		error_code = 2233
		!time.is_a?(Integer) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_interval_type(interval)
		error_code = 2234
		!interval.is_a?(Integer) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_title_type(title)
		error_code = 2235
		!title.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_body_type(body)
		error_code = 2236
		!body.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_path_type(path)
		error_code = 2237
		!path.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_method_type(method)
		error_code = 2238
		!method.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_commands_type(commands)
		error_code = 2239
		!commands.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_caching_type(caching)
		error_code = 2240
		(!caching.is_a?(TrueClass) && !caching.is_a?(FalseClass)) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_params_type(params)
		error_code = 2241
		!params.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_errors_type(errors)
		error_code = 2242
		!errors.is_a?(Array) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_code_type(code)
		error_code = 2243
		!code.is_a?(Integer) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_message_type(message)
		error_code = 2244
		!message.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_env_vars_type(env_vars)
		error_code = 2245
		!env_vars.is_a?(Hash) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_env_var_name_type(name)
		error_code = 2246
		!name.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_env_var_value_type(value)
		error_code = 2247
		return get_validation_hash if value.is_a?(TrueClass)
		return get_validation_hash if value.is_a?(FalseClass)
		return get_validation_hash if value.is_a?(String)
		return get_validation_hash if value.is_a?(Integer)
		return get_validation_hash if value.is_a?(Float)
		return get_validation_hash if value.is_a?(Array)
		get_validation_hash(error_code, 400)
	end

	def self.validate_table_objects_type(table_objects)
		error_code = 2248
		return get_validation_hash(error_code, 400) if !table_objects.is_a?(Array)
		table_objects.each do |obj|
			return get_validation_hash(error_code, 400) if !obj.is_a?(String)
		end

		get_validation_hash
	end

	def self.validate_slot_type(slot)
		error_code = 2249
		!slot.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_plan_type(plan)
		error_code = 2250
		!plan.is_a?(Integer) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_success_url_type(success_url)
		error_code = 2251
		!success_url.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_cancel_url_type(cancel_url)
		error_code = 2252
		!cancel_url.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_mode_type(mode)
		error_code = 2253
		!mode.is_a?(String) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_schema_type(schema)
		error_code = 2254
		!schema.is_a?(Hash) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_price_type(price)
		error_code = 2255
		!price.is_a?(Integer) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	# Too short & too long fields
	def self.validate_first_name_length(first_name)
		if first_name.length < Constants::FIRST_NAME_MIN_LENGTH
			get_validation_hash(2300, 400)
		elsif first_name.length > Constants::FIRST_NAME_MAX_LENGTH
			get_validation_hash(2400, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_password_length(password)
		if password.length < Constants::PASSWORD_MIN_LENGTH
			get_validation_hash(2301, 400)
		elsif password.length > Constants::PASSWORD_MAX_LENGTH
			get_validation_hash(2401, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_device_name_length(device_name)
		if device_name.length < Constants::DEVICE_NAME_MIN_LENGTH
			get_validation_hash(2302, 400)
		elsif device_name.length > Constants::DEVICE_NAME_MAX_LENGTH
			get_validation_hash(2402, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_device_os_length(device_os)
		if device_os.length < Constants::DEVICE_OS_MIN_LENGTH
			get_validation_hash(2304, 400)
		elsif device_os.length > Constants::DEVICE_OS_MAX_LENGTH
			get_validation_hash(2404, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_name_length(name)
		if name.length < Constants::NAME_MIN_LENGTH
			get_validation_hash(2305, 400)
		elsif name.length > Constants::NAME_MAX_LENGTH
			get_validation_hash(2405, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_api_function_name_length(name)
		if name.length < Constants::API_FUNCTION_NAME_MIN_LENGTH
			get_validation_hash(2305, 400)
		elsif name.length > Constants::API_FUNCTION_NAME_MAX_LENGTH
			get_validation_hash(2405, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_description_length(description)
		if description.length < Constants::DESCRIPTION_MIN_LENGTH
			get_validation_hash(2306, 400)
		elsif description.length > Constants::DESCRIPTION_MAX_LENGTH
			get_validation_hash(2406, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_web_link_length(web_link)
		if web_link.length < Constants::WEB_LINK_MIN_LENGTH
			get_validation_hash(2307, 400)
		elsif web_link.length > Constants::WEB_LINK_MAX_LENGTH
			get_validation_hash(2407, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_google_play_link_length(google_play_link)
		if google_play_link.length < Constants::GOOGLE_PLAY_LINK_MIN_LENGTH
			get_validation_hash(2308, 400)
		elsif google_play_link.length > Constants::GOOGLE_PLAY_LINK_MAX_LENGTH
			get_validation_hash(2408, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_microsoft_store_link_length(microsoft_store_link)
		if microsoft_store_link.length < Constants::MICROSOFT_STORE_LINK_MIN_LENGTH
			get_validation_hash(2309, 400)
		elsif microsoft_store_link.length > Constants::MICROSOFT_STORE_LINK_MAX_LENGTH
			get_validation_hash(2409, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_property_name_length(name)
		if name.length < Constants::PROPERTY_NAME_MIN_LENGTH
			get_validation_hash(2310, 400)
		elsif name.length > Constants::PROPERTY_NAME_MAX_LENGTH
			get_validation_hash(2410, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_property_value_length(value)
		return get_validation_hash if !value.is_a?(String)

		if value.length < Constants::PROPERTY_VALUE_MIN_LENGTH
			get_validation_hash(2311, 400)
		elsif value.length > Constants::PROPERTY_VALUE_MAX_LENGTH
			get_validation_hash(2411, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_ext_length(ext)
		if ext.length < Constants::EXT_MIN_LENGTH
			get_validation_hash(2312, 400)
		elsif ext.length > Constants::EXT_MAX_LENGTH
			get_validation_hash(2412, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_product_name_length(product_name)
		if product_name.length < Constants::PRODUCT_NAME_MIN_LENGTH
			get_validation_hash(2315, 400)
		elsif product_name.length > Constants::PRODUCT_NAME_MAX_LENGTH
			get_validation_hash(2415, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_product_image_length(product_image)
		if product_image.length > Constants::PRODUCT_IMAGE_MAX_LENGTH
			get_validation_hash(2416, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_endpoint_length(endpoint)
		if endpoint.length < Constants::ENDPOINT_MIN_LENGTH
			get_validation_hash(2317, 400)
		elsif endpoint.length > Constants::ENDPOINT_MAX_LENGTH
			get_validation_hash(2417, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_p256dh_length(p256dh)
		if p256dh.length < Constants::P256DH_MIN_LENGTH
			get_validation_hash(2318, 400)
		elsif p256dh.length > Constants::P256DH_MAX_LENGTH
			get_validation_hash(2418, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_auth_length(auth)
		if auth.length < Constants::AUTH_MIN_LENGTH
			get_validation_hash(2319, 400)
		elsif auth.length > Constants::AUTH_MAX_LENGTH
			get_validation_hash(2419, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_title_length(title)
		if title.length < Constants::TITLE_MIN_LENGTH
			get_validation_hash(2320, 400)
		elsif title.length > Constants::TITLE_MAX_LENGTH
			get_validation_hash(2420, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_body_length(body)
		if body.length < Constants::BODY_MIN_LENGTH
			get_validation_hash(2321, 400)
		elsif body.length > Constants::BODY_MAX_LENGTH
			get_validation_hash(2421, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_path_length(path)
		if path.length < Constants::PATH_MIN_LENGTH
			get_validation_hash(2322, 400)
		elsif path.length > Constants::PATH_MAX_LENGTH
			get_validation_hash(2422, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_commands_length(commands)
		if commands.length < Constants::COMMANDS_MIN_LENGTH
			get_validation_hash(2323, 400)
		elsif commands.length > Constants::COMMANDS_MAX_LENGTH
			get_validation_hash(2423, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_params_length(params)
		if params.length < Constants::PARAMS_MIN_LENGTH
			get_validation_hash(2324, 400)
		elsif params.length > Constants::PARAMS_MAX_LENGTH
			get_validation_hash(2424, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_message_length(message)
		if message.length < Constants::MESSAGE_MIN_LENGTH
			get_validation_hash(2325, 400)
		elsif message.length > Constants::MESSAGE_MAX_LENGTH
			get_validation_hash(2425, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_env_var_name_length(name)
		if name.length < Constants::ENV_VAR_NAME_MIN_LENGTH
			get_validation_hash(2326, 400)
		elsif name.length > Constants::ENV_VAR_NAME_MAX_LENGTH
			get_validation_hash(2426, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_env_var_value_length(value)
		if value.length < Constants::ENV_VAR_VALUE_MIN_LENGTH
			get_validation_hash(2327, 400)
		elsif value.length > Constants::ENV_VAR_VALUE_MAX_LENGTH
			get_validation_hash(2427, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_slot_length(slot)
		if slot.length < Constants::SLOT_MIN_LENGTH
			get_validation_hash(2328, 400)
		elsif slot.length > Constants::SLOT_MAX_LENGTH
			get_validation_hash(2428, 400)
		else
			get_validation_hash
		end
	end

	# Invalid fields
	def self.validate_email_validity(email)
		error_code = 2500
		!validate_email(email) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_name_validity(name)
		error_code = 2501
		!validate_name(name) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_web_link_validity(web_link)
		error_code = 2502
		(web_link.length > 0 && !validate_url(web_link)) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_google_play_link_validity(google_play_link)
		error_code = 2503
		(google_play_link.length > 0 && !validate_url(google_play_link)) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_microsoft_store_link_validity(microsoft_store_link)
		error_code = 2504
		(microsoft_store_link.length > 0 && !validate_url(microsoft_store_link)) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_method_validity(method)
		error_code = 2505
		!validate_method(method) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_slot_validity(slot)
		error_code = 2506
		!validate_slot(slot) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_plan_validity(plan)
		error_code = 2507
		(plan != 1 && plan != 2) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_success_url_validity(success_url)
		error_code = 2508
		!validate_url(success_url) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_cancel_url_validity(cancel_url)
		error_code = 2509
		!validate_url(cancel_url) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_mode_validity(mode)
		error_code = 2510
		(mode != "setup" && mode != "subscription" && mode != "payment") ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_product_image_validity(product_image)
		error_code = 2511
		!validate_url(product_image) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_price_validity(price)
		error_code = 2512
		!validate_price(price) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_currency_validity(currency)
		error_code = 2513
		!validate_currency(currency) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	# Generic state errors
	def self.validate_user_not_confirmed(user)
		error_code = 3000
		user.confirmed ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_user_is_provider(user)
		error_code = 3001
		user.provider.nil? ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	def self.validate_table_objects_already_purchased(user, table_objects)
		error_code = 3002

		table_objects.each do |obj|
			# Check if the table object was already purchased by the user
			return get_validation_hash(error_code, 422) if !user.purchases.find { |p| p.table_objects.include?(obj) && p.completed }.nil?
		end

		get_validation_hash
	end

	def self.validate_user_is_stripe_customer(user)
		error_code = 3003
		user.stripe_customer_id.nil? ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	def self.validate_user_has_payment_method(payment_methods)
		error_code = 3003
		payment_methods.data.size == 0 ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	def self.validate_user_has_no_stripe_customer(user)
		error_code = 3004
		!user.stripe_customer_id.nil? ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	def self.validate_table_object_is_file(table_object)
		error_code = 3005
		!table_object.file ? get_validation_hash(error_code, 422) : get_validation_hash
	end

	def self.raise_table_object_has_no_file
		error_code = 3006
		raise RuntimeError, [get_validation_hash(error_code, 404)].to_json
	end

	def self.validate_sufficient_storage(free_storage, file_size)
		error_code = 3007
		free_storage < file_size ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_table_objects_belong_to_same_user(table_objects)
		error_code = 3009
		return get_validation_hash if table_objects.count == 0

		obj_user = table_objects.first.user
		i = 1

		while i < table_objects.count
			return get_validation_hash(error_code, 412) if table_objects[i].user != obj_user
			i += 1
		end

		get_validation_hash
	end

	def self.validate_purchase_can_be_deleted(purchase)
		error_code = 3010
		purchase.price > 0 && purchase.completed ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	def self.validate_user_is_below_plan(user, plan)
		error_code = 3011
		user.plan >= plan ? get_validation_hash(error_code, 422) : get_validation_hash
	end

	# Access token errors
	def self.get_session_from_token(token, check_renew = true)
		session = Session.find_by(token: token)

		if session.nil?
			# Check if there is a session with old_token = token
			session = Session.find_by(old_token: token)

			if session.nil?
				# Session does not exist
				raise RuntimeError, [get_validation_hash(3603, 404)].to_json
			else
				# The old token was used
				# Delete the session, as the token may be stolen
				session.destroy!
				raise RuntimeError, [get_validation_hash(3100, 403)].to_json
			end
		elsif check_renew
			# Check if the session needs to be renewed
			if !Rails.env.development? && (Time.now - session.updated_at) > 1.day
				raise RuntimeError, [get_validation_hash(3101, 403)].to_json
			end
		end

		return session
	end

	# Incorrect values
	def self.authenticate_user(user, password)
		error_code = 3200
		!user.authenticate(password) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_email_confirmation_token_of_user(user, email_confirmation_token)
		error_code = 3201
		user.email_confirmation_token != email_confirmation_token ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	def self.validate_password_confirmation_token_of_user(user, password_confirmation_token)
		error_code = 3202
		user.password_confirmation_token != password_confirmation_token ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	# Not supported values
	def self.validate_country_supported(country)
		error_code = 3300
		![
			"de",
			"at",
			"us"
		].include?(country.downcase) ? get_validation_hash(error_code, 400) : get_validation_hash
	end

	# Errors for values already in use
	def self.validate_table_object_uuid_availability(uuid)
		error_code = 3400
		TableObject.exists?(uuid: uuid) ? get_validation_hash(error_code, 409) : get_validation_hash
	end

	def self.validate_web_push_subscription_uuid_availability(uuid)
		error_code = 3400
		WebPushSubscription.exists?(uuid: uuid) ? get_validation_hash(error_code, 409) : get_validation_hash
	end

	def self.validate_notification_uuid_availability(uuid)
		error_code = 3400
		Notification.exists?(uuid: uuid) ? get_validation_hash(error_code, 409) : get_validation_hash
	end

	def self.validate_email_availability(email)
		error_code = 3401
		User.exists?(email: email) ? get_validation_hash(error_code, 409) : get_validation_hash
	end

	# Errors for empty values in User
	def self.validate_old_email_of_user_not_empty(user)
		error_code = 3500
		user.old_email.nil? ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	def self.validate_new_email_of_user_not_empty(user)
		error_code = 3501
		user.new_email.nil? ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	def self.validate_new_password_of_user_not_empty(user)
		error_code = 3502
		user.new_password.nil? ? get_validation_hash(error_code, 412) : get_validation_hash
	end

	# Errors for not existing resources
	def self.validate_user_existence(user)
		error_code = 3600
		user.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_dev_existence(dev)
		error_code = 3601
		dev.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_provider_existence(provider)
		error_code = 3602
		provider.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_session_existence(session)
		error_code = 3603
		session.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_app_existence(app)
		error_code = 3604
		app.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_table_existence(table)
		error_code = 3605
		table.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_table_object_existence(table_object)
		error_code = 3606
		table_object.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_table_object_price_existence(table_object_price)
		error_code = 3607
		table_object_price.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_table_object_user_access_existence(access)
		error_code = 3608
		access.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_purchase_existence(purchase)
		error_code = 3609
		purchase.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_web_push_subscription_existence(web_push_subscription)
		error_code = 3610
		web_push_subscription.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_notification_existence(notification)
		error_code = 3611
		notification.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_api_existence(api)
		error_code = 3612
		api.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_api_endpoint_existence(api_endpoint)
		error_code = 3613
		api_endpoint.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_compiled_api_endpoint_existence(compiled_api_endpoint)
		error_code = 3614
		compiled_api_endpoint.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	def self.validate_api_slot_existence(api_slot)
		error_code = 3615
		api_slot.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end
	
	def self.validate_collection_existence(collection)
		error_code = 3616
		collection.nil? ? get_validation_hash(error_code, 404) : get_validation_hash
	end

	# Errors for already existing resources
	def self.validate_provider_nonexistence(provider)
		error_code = 3702
		!provider.nil? ? get_validation_hash(error_code, 422) : get_validation_hash
	end

	# Utility methods
	def self.validate_email(email)
		/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/.match?(email)
	end

	def self.validate_name(name)
		/^([A-Z]|[a-z])+$/.match?(name)
	end

	def self.validate_method(method)
		["get", "post", "put", "delete"].include?(method.downcase)
	end

	def self.validate_url(url)
		/^(https?:\/\/)?([\w.-]+(\.[\w.-]+)+|localhost:[0-9]{1,4})[\w\-._~\/?#@&\+,;=]+$/.match?(url)
	end

	def self.validate_slot(slot)
		/^\w+$/.match?(name)
	end

	def self.validate_price(price)
		return price >= 0 && price <= 100000
	end

	def self.validate_currency(currency)
		return ["eur"].include?(currency.downcase)
	end

	# Error methods
	def self.raise_validation_errors(validations)
		if validations.is_a?(Hash)
			raise RuntimeError, [validations].to_json if !validations[:success]
		elsif validations.is_a?(Array)
			errors = Array.new
			validations.each do |validation|
				errors.push(validation) if !validation[:success]
			end

			raise RuntimeError, errors.to_json if errors.length > 0
		end
	end

	def self.get_errors_of_validations(validations)
		errors = Array.new
		validations.each do |validation|
			errors.push(validation["error"])
		end

		return errors
	end

	def self.get_validation_hash(error_code = 0, status_code = 200)
		if error_code == 0
			{
				success: true
			}
		else
			{
				success: false,
				error: {code: error_code, message: get_error_message(error_code)},
				status: status_code
			}
		end
	end

	def self.get_error_message(code)
		case code
		# Generic request errors
		when 1000
			"Unexpected error"
		when 1001
			"Authentication failed"
		when 1002
			"Action not allowed"
		when 1003
			"Content-Type not supported"
		# Errors for missing headers
		when 1100
			"Missing header: Authorization"
		when 1101
			"Missing header: Content-Type"
		# File errors
		when 1200
			"Content-Type header does not match the file type"
		when 1201
			"Image file invalid"
		when 1202
			"Image file too large"
		# Generic request body errors
		when 2000
			"Invalid body"
		when 2001
			"Purchase requires at least one table object"
		# Missing fields
		when 2100
			"Missing field: access_token"
		when 2101
			"Missing field: app_id"
		when 2102
			"Missing field: table_id"
		when 2103
			"Missing field: email"
		when 2104
			"Missing field: first_name"
		when 2105
			"Missing field: password"
		when 2106
			"Missing field: email_confirmation_token"
		when 2107
			"Missing field: password_confirmation_token"
		when 2108
			"Missing field: country"
		when 2109
			"Missing field: api_key"
		when 2110
			"Missing field: name"
		when 2111
			"Missing field: description"
		when 2112
			"Missing field: properties"
		when 2115
			"Missing field: product_name"
		when 2116
			"Missing field: product_image"
		when 2117
			"Missing field: currency"
		when 2118
			"Missing field: endpoint"
		when 2119
			"Missing field: p256dh"
		when 2120
			"Missing field: auth"
		when 2121
			"Missing field: time"
		when 2122
			"Missing field: interval"
		when 2123
			"Missing field: title"
		when 2124
			"Missing field: body"
		when 2125
			"Missing field: path"
		when 2126
			"Missing field: method"
		when 2127
			"Missing field: commands"
		when 2128
			"Missing field: errors"
		when 2129
			"Missing field: env_vars"
		when 2130
			"Missing field: table_objects"
		when 2131
			"Missing field: slot"
		when 2132
			"Missing field: plan"
		when 2133
			"Missing field: success_url"
		when 2134
			"Missing field: cancel_url"
		when 2135
			"Missing field: price"
		# Fields with wrong type
		when 2200
			"Field has wrong type: access_token"
		when 2201
			"Field has wrong type: uuid"
		when 2202
			"Field has wrong type: app_id"
		when 2203
			"Field has wrong type: table_id"
		when 2204
			"Field has wrong type: email"
		when 2205
			"Field has wrong type: first_name"
		when 2206
			"Field has wrong type: password"
		when 2207
			"Field has wrong type: email_confirmation_token"
		when 2208
			"Field has wrong type: password_confirmation_token"
		when 2209
			"Field has wrong type: country"
		when 2210
			"Field has wrong type: api_key"
		when 2211
			"Field has wrong type: device_name"
		when 2213
			"Field has wrong type: device_os"
		when 2214
			"Field has wrong type: name"
		when 2215
			"Field has wrong type: description"
		when 2216
			"Field has wrong type: published"
		when 2217
			"Field has wrong type: web_link"
		when 2218
			"Field has wrong type: google_play_link"
		when 2219
			"Field has wrong type: microsoft_store_link"
		when 2220
			"Field has wrong type: file"
		when 2221
			"Field has wrong type: properties"
		when 2222
			"Field has wrong type: property name"
		when 2223
			"Field has wrong type: property value"
		when 2224
			"Field has wrong type: ext"
		when 2227
			"Field has wrong type: product_name"
		when 2228
			"Field has wrong type: product_image"
		when 2229
			"Field has wrong type: currency"
		when 2230
			"Field has wrong type: endpoint"
		when 2231
			"Field has wrong type: p256dh"
		when 2232
			"Field has wrong type: auth"
		when 2233
			"Field has wrong type: time"
		when 2234
			"Field has wrong type: interval"
		when 2235
			"Field has wrong type: title"
		when 2236
			"Field has wrong type: body"
		when 2237
			"Field has wrong type: path"
		when 2238
			"Field has wrong type: method"
		when 2239
			"Field has wrong type: commands"
		when 2240
			"Field has wrong type: caching"
		when 2241
			"Field has wrong type: params"
		when 2242
			"Field has wrong type: errors"
		when 2243
			"Field has wrong type: code"
		when 2244
			"Field has wrong type: message"
		when 2245
			"Field has wrong type: env_vars"
		when 2246
			"Field has wrong type: env_var name"
		when 2247
			"Field has wrong type: env_var value"
		when 2248
			"Field has wrong type: table_objects"
		when 2249
			"Field has wrong type: slot"
		when 2250
			"Field has wrong type: plan"
		when 2251
			"Field has wrong type: success_url"
		when 2252
			"Field has wrong type: cancel_url"
		when 2253
			"Field has wrong type: mode"
		when 2254
			"Field has wrong type: schema"
		when 2255
			"Field has wrong type: price"
		# Too short fields
		when 2300
			"Field too short: first_name"
		when 2301
			"Field too short: password"
		when 2302
			"Field too short: device_name"
		when 2304
			"Field too short: device_os"
		when 2305
			"Field too short: name"
		when 2306
			"Field too short: description"
		when 2307
			"Field too short: web_link"
		when 2308
			"Field too short: google_play_link"
		when 2309
			"Field too short: microsoft_store_link"
		when 2310
			"Field too short: property name"
		when 2311
			"Field too short: property value"
		when 2312
			"Field too short: ext"
		when 2315
			"Field too short: product_name"
		when 2316
			"Field too short: product_image"
		when 2317
			"Field too short: endpoint"
		when 2318
			"Field too short: p256dh"
		when 2319
			"Field too short: auth"
		when 2320
			"Field too short: title"
		when 2321
			"Field too short: body"
		when 2322
			"Field too short: path"
		when 2323
			"Field too short: commands"
		when 2324
			"Field too short: params"
		when 2325
			"Field too short: message"
		when 2326
			"Field too short: env_var name"
		when 2327
			"Field too short: env_var value"
		when 2328
			"Field too short: slot"
		# Too long fields
		when 2400
			"Field too long: first_name"
		when 2401
			"Field too long: password"
		when 2402
			"Field too long: device_name"
		when 2404
			"Field too long: device_os"
		when 2405
			"Field too long: name"
		when 2406
			"Field too long: description"
		when 2407
			"Field too long: web_link"
		when 2408
			"Field too long: google_play_link"
		when 2409
			"Field too long: microsoft_store_link"
		when 2410
			"Field too long: property name"
		when 2411
			"Field too long: property value"
		when 2412
			"Field too long: ext"
		when 2415
			"Field too long: product_name"
		when 2416
			"Field too long: product_image"
		when 2417
			"Field too long: endpoint"
		when 2418
			"Field too long: p256dh"
		when 2419
			"Field too long: auth"
		when 2420
			"Field too long: title"
		when 2421
			"Field too long: body"
		when 2422
			"Field too long: path"
		when 2423
			"Field too long: commands"
		when 2424
			"Field too long: params"
		when 2425
			"Field too long: message"
		when 2426
			"Field too long: env_var name"
		when 2427
			"Field too long: env_var value"
		when 2428
			"Field too long: slot"
		# Invalid fields
		when 2500
			"Field invalid: email"
		when 2501
			"Field invalid: name"
		when 2502
			"Field invalid: web_link"
		when 2503
			"Field invalid: google_play_link"
		when 2504
			"Field invalid: microsoft_store_link"
		when 2505
			"Field invalid: method"
		when 2506
			"Field invalid: slot"
		when 2507
			"Field invalid: plan"
		when 2508
			"Field invalid: success_url"
		when 2509
			"Field invalid: cancel_url"
		when 2510
			"Field invalid: mode"
		when 2511
			"Field invalid: product_image"
		when 2512
			"Field invalid: price"
		when 2513
			"Field invalid: currency"
		# Generic state errors
		when 3000
			"The user is already confirmed"
		when 3001
			"The user of the TableObject must have a Provider"
		when 3002
			"The user already purchased one of the TableObjects"
		when 3003
			"The user has no payment information"
		when 3004
			"The user already has a stripe customer"
		when 3005
			"The table object is not a file"
		when 3006
			"The table object has no file"
		when 3007
			"Not sufficient storage available"
		when 3009
			"The table objects need to belong to the same user"
		when 3010
			"The purchase cannot be deleted"
		when 3011
			"The user is already on this or a higher plan"
		# Access token errors
		when 3100
			"Can't use old access token"
		when 3101
			"Access token must be renewed"
		# Incorrect values
		when 3200
			"Incorrect value: password"
		when 3201
			"Incorrect value: email_confirmation_token"
		when 3202
			"Incorrect value: password_confirmation_token"
		# Not supported values
		when 3300
			"Value not supported: country"
		# Errors for values already in use
		when 3400
			"Value already in use: uuid"
		when 3401
			"Value already in use: email"
		# Errors for empty values in User
		when 3500
			"User.old_email is empty"
		when 3501
			"User.new_email is empty"
		when 3502
			"User.new_password is empty"
		# Errors for not existing resources
		when 3600
			"Resource does not exist: User"
		when 3601
			"Resource does not exist: Dev"
		when 3602
			"Resource does not exist: Provider"
		when 3603
			"Resource does not exist: Session"
		when 3604
			"Resource does not exist: App"
		when 3605
			"Resource does not exist: Table"
		when 3606
			"Resource does not exist: TableObject"
		when 3607
			"Resource does not exist: TableObjectPrice"
		when 3608
			"Resource does not exist: TableObjectUserAccess"
		when 3609
			"Resource does not exist: Purchase"
		when 3610
			"Resource does not exist: WebPushSubscription"
		when 3611
			"Resource does not exist: Notification"
		when 3612
			"Resource does not exist: Api"
		when 3613
			"Resource does not exist: ApiEndpoint"
		when 3614
			"Resource does not exist: CompiledApiEndpoint"
		when 3615
			"Resource does not exist: ApiSlot"
		when 3616
			"Resource does not exist: Collection"
		# Errors for already existing resources
		when 3700
			"Resource already exists: User"
		when 3701
			"Resource already exists: Dev"
		when 3702
			"Resource already exists: Provider"
		when 3703
			"Resource already exists: Session"
		when 3704
			"Resource already exists: App"
		when 3705
			"Resource already exists: Table"
		when 3706
			"Resource already exists: TableObject"
		when 3707
			"Resource already exists: TableObjectPrice"
		when 3708
			"Resource already exists: TableObjectUserAccess"
		when 3709
			"Resource already exists: Purchase"
		when 3710
			"Resource already exists: WebPushSubscription"
		when 3711
			"Resource already exists: Notification"
		when 3712
			"Resource already exists: Api"
		when 3713
			"Resource already exists: ApiEndpoint"
		when 3714
			"Resource already exists: CompiledApiEndpoint"
		when 3715
			"Resource already exists: ApiSlot"
		when 3716
			"Resource already exists: Collection"
		end
	end
end