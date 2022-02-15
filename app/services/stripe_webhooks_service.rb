class StripeWebhooksService
	def self.InvoicePaymentSucceededEvent(event)
		period_end = event.data.object.lines.data[0].period.end if event.data.object.lines.data.count > 0
		product_id = event.data.object.lines.data[0].plan.product if event.data.object.lines.data.count > 0
		amount = event.data.object.lines.data[0].amount
		charge = event.data.object.charge

		user = User.find_by(stripe_customer_id: event.data.object.customer)

		if !user.nil?
			# Update plan, period_end and subscription_status of the user
			user.period_end = Time.at(period_end) if !period_end.nil?
			user.subscription_status = 0

			case product_id
         when ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
            user.plan = 1
         when ENV['STRIPE_DAV_PRO_PRODUCT_ID']
            user.plan = 2
         end

			user.save

			# Get all apps of the user
			apps = Array.new		# Array<{id: int, providers: Array<{id: int, count: int}>}>

			user.apps.each do |app|
				apps.push({
					id: app.id,
					providers: Array.new
				})
			end

			if apps.size > 0
				# Go through each TableObjectUserAccess of the user
				user.table_object_user_access.each do |access|
					next if access.table_object.user == user
					next if access.table_object.user.provider.nil?
					app_id = access.table_object.table.app.id
					provider_id = access.table_object.user.provider.id

					# Add the provider to the app
					app_index = apps.index { |app| app[:id] == app_id }
					next if app_index.nil?

					# Find the provider in the app
					provider_index = apps[app_index][:providers].index { |provider| provider[:id] == provider_id }

					if provider_index.nil?
						# Add the provider to the app
						apps[app_index][:providers].push({
							id: provider_id,
							count: 1
						})
					else
						# Increase the count of the provider
						apps[app_index][:providers][provider_index][:count] = apps[app_index][:providers][provider_index][:count] + 1
					end
				end

				# Calculate the shares and send the money to the providers
				app_share = (amount * 0.8).round / apps.size

				apps.each do |app|
					next if app[:providers].size == 0
					total_share_count = 0

					app[:providers].each do |provider_hash|
						total_share_count = total_share_count + provider_hash[:count]
					end

					share = app_share / total_share_count

					# TODO: Send the app share to the appropriate dev if necessary

					app[:providers].each do |provider_hash|
						# Get the provider
						provider = Provider.find_by(id: provider_hash[:id])
						provider_amount = share * provider_hash[:count]

						# Get the connected account from the Stripe API
						connected_account = Stripe::Account.retrieve(provider.stripe_account_id)
						next if connected_account.nil?

						# TODO: Check if the connected account is in a SEPA country

						# Create the transfer
						transfer = Stripe::Transfer.create({
							amount: provider_amount,
							currency: 'eur',
							destination: provider.stripe_account_id,
							source_transaction: charge
						})
					end
				end
			end
		end

		200
	end

	def self.InvoicePaymentFailedEvent(event)
		paid = event.data.object.paid
		attempt_count = event.data.object.attempt_count
      next_payment_attempt = event.data.object.next_payment_attempt

		if !paid
			if next_payment_attempt.nil?
				# Change the plan to free
				user = User.find_by(stripe_customer_id: event.data.object.customer)
	
				if !user.nil?
					user.plan = 0
					user.subscription_status = 0
					user.period_end = nil
					user.save
	
					# Send failed payment email
					UserNotifierMailer.payment_failed(user).deliver_later
				end
			elsif attempt_count == 2
				# Send email for failed payment attempt
				UserNotifierMailer.payment_attempt_failed(user).deliver_later
			end
		end

		200
	end

	def self.CustomerSubscriptionCreatedEvent(event)
		period_end = event.data.object.current_period_end
		product_id = event.data.object.items.data[0].plan.product if event.data.object.items.data.count > 0

		user = User.find_by(stripe_customer_id: event.data.object.customer)

		if !user.nil?
			# Update plan, period_end and subscription_status of the user
			user.period_end = Time.at(period_end) if !period_end.nil?
			user.subscription_status = 0

			case product_id
         when ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
            user.plan = 1
         when ENV['STRIPE_DAV_PRO_PRODUCT_ID']
            user.plan = 2
         end

			user.save
		end

		200
	end

	def self.CustomerSubscriptionUpdatedEvent(event)
		period_end = event.data.object.current_period_end
		cancelled = event.data.object.cancel_at_period_end
		product_id = event.data.object.items.data[0].plan.product if event.data.object.items.data.count > 0

		user = User.find_by(stripe_customer_id: event.data.object.customer)

		if !user.nil?
			# Update plan, period_end and subscription_status of the user
			user.period_end = Time.at(period_end) if !period_end.nil?
			user.subscription_status = cancelled ? 1 : 0

			case product_id
         when ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
            user.plan = 1
         when ENV['STRIPE_DAV_PRO_PRODUCT_ID']
            user.plan = 2
         end

			user.save
		end

		200
	end

	def self.CustomerSubscriptionDeletedEvent(event)
		user = User.find_by(stripe_customer_id: event.data.object.customer)

		if !user.nil?
			# Downgrade the plan to free, clear the period_end field and change the subscription_status to active
			user.plan = 0
			user.subscription_status = 0
			user.period_end = nil

			user.save
		end

		200
	end
end