class UserNotifierMailer < ApplicationMailer
	default :from => 'no-reply@dav-apps.tech'

	def email_confirmation(user)
		@user = user
		@link = "#{ENV['WEBSITE_BASE_URL']}/email-link?type=confirmUser&userId=#{@user.id}&emailConfirmationToken=#{@user.email_confirmation_token}"

		make_bootstrap_mail(
			to: @user.email,
			subject: "Confirm your email address"
		)
	end

	def password_reset(user)
		@user = user
		@link = "#{ENV['WEBSITE_BASE_URL']}/reset-password?userId=#{@user.id}&passwordConfirmationToken=#{@user.password_confirmation_token}"

		make_bootstrap_mail(
			to: @user.email,
			subject: "Reset your password"
		)
	end

	def change_email(user)
		@user = user
		@link = "#{ENV['WEBSITE_BASE_URL']}/email-link?type=changeEmail&userId=#{@user.id}&emailConfirmationToken=#{@user.email_confirmation_token}"

		make_bootstrap_mail(
			to: @user.new_email,
			subject: "Confirm your new email address"
		)
	end

	def change_password(user)
		@user = user
		@link = "#{ENV['WEBSITE_BASE_URL']}/email-link?type=changePassword&userId=#{@user.id}&passwordConfirmationToken=#{@user.password_confirmation_token}"

		make_bootstrap_mail(
			to: @user.email,
			subject: "Confirm your new password"
		)
	end

	def reset_email(user)
		@user = user
		@link = "#{ENV['WEBSITE_BASE_URL']}/email-link?type=resetEmail&userId=#{@user.id}&emailConfirmationToken=#{@user.email_confirmation_token}"

		make_bootstrap_mail(
			to: @user.old_email,
			subject: "Your email address was changed"
		)
	end

	def payment_failed(user)
		@user = user
		@link = "#{ENV['WEBSITE_BASE_URL']}/login?redirect=user%23plans"

		make_bootstrap_mail(
			to: @user.email,
			subject: "Subscription renewal not possible"
		)
	end
end
