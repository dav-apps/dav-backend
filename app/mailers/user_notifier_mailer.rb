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
end
