class TableObjectUpdateChannel < ApplicationCable::Channel
	def subscribed
      stream_from "table_object_update:#{user.id},#{app.id}"
   end
end