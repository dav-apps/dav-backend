class ApplicationController < ActionController::API
	def get_authorization_header
		request.headers['HTTP_AUTHORIZATION']
	end
end
