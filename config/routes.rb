Rails.application.routes.draw do
	match '/v1/signup', via: :post, to: 'users#signup'
end
