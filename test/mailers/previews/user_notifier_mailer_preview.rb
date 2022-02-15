class UserNotifierMailerPreview < ActionMailer::Preview
	def email_confirmation
		UserNotifierMailer.email_confirmation(User.first)
	end

	def password_reset
		UserNotifierMailer.password_reset(User.first)
	end

	def change_email
		UserNotifierMailer.change_email(User.first)
	end

	def change_password
		UserNotifierMailer.change_password(User.first)
	end

	def reset_email
		UserNotifierMailer.reset_email(User.first)
	end
end