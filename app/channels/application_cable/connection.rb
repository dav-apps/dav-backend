module ApplicationCable
	class Connection < ActionCable::Connection::Base
		identified_by :user, :app

		def connect
			# Get the connection token
			token = request.params["token"]
			reject_unauthorized_connection if token.nil?

			# Try to find the corresponding connection
			connection = WebsocketConnection.find_by(token: token)
			reject_unauthorized_connection if connection.nil?

			# Check the age of the connection
			reject_unauthorized_connection if connection.created_at + 5.minutes < Time.now

			self.user = connection.user
			self.app = connection.app

			# Delete the connection
			connection.destroy!
		end
	end
end
