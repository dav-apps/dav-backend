class ApplicationController < ActionController::API
	def get_auth
		auth = request.headers['HTTP_AUTHORIZATION']
		return auth.split(' ').last if !auth.nil?
		nil
	end

	def get_jwt
		# session JWT: header.payload.signature.session_id
		auth = request.headers['HTTP_AUTHORIZATION']
		return nil if !auth
		split_jwt(auth)
	end

	def split_jwt(jwt)
		jwt_parts = jwt.split(' ').last.split('.')
		jwt = jwt_parts[0..2].join('.')
		session_id = jwt_parts[3].to_i

		return [jwt, session_id]
	end

	def get_content_type
		type = request.headers["Content-Type"]
		type = request.headers["CONTENT_TYPE"] if type.nil?
		type = request.headers["HTTP_CONTENT_TYPE"] if type.nil?
		type
	end
end