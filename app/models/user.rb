class User < ApplicationRecord
	has_one :dev, dependent: :destroy
end