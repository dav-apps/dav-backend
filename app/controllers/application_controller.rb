class ApplicationController < ActionController::API
	def get_auth
		auth = request.headers['HTTP_AUTHORIZATION']
		return auth.split(' ').last if !auth.nil?
		nil
	end

	def get_content_type
		type = request.headers["Content-Type"]
		type = request.headers["CONTENT_TYPE"] if type.nil?
		type = request.headers["HTTP_CONTENT_TYPE"] if type.nil?
		type
	end
end