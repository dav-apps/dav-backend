class UserNotifierMailer < ApplicationMailer
	default :from => 'no-reply@dav-apps.tech'

	def email_confirmation(user)
		@user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=confirm_user&user_id=#{@user.id}&email_confirmation_token=#{@user.email_confirmation_token}"

		make_bootstrap_mail(
			to: @user.email,
			subject: "Confirm your email address"
		)
	end

	def password_reset(user)
		@user = user
		@link = "#{ENV['BASE_URL']}/reset_password?user_id=#{@user.id}&password_confirmation_token=#{@user.password_confirmation_token}"

		make_bootstrap_mail(
			to: @user.email,
			subject: "Reset your password"
		)
	end

	def change_email(user)
		@user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=change_email&user_id=#{@user.id}&email_confirmation_token=#{@user.email_confirmation_token}"

		make_bootstrap_mail(
			to: @user.new_email,
			subject: "Confirm your new email address"
		)
	end

	def change_password(user)
		@user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=change_password&user_id=#{@user.id}&password_confirmation_token=#{@user.password_confirmation_token}"

		make_bootstrap_mail(
			to: @user.email,
			subject: "Confirm your new password"
		)
	end

	def reset_email(user)
		@user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=reset_email&user_id=#{@user.id}&email_confirmation_token=#{@user.email_confirmation_token}"

		make_bootstrap_mail(
			to: @user.old_email,
			subject: "Your email address was changed"
		)
	end
end
