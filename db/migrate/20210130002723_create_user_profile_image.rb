class CreateUserProfileImage < ActiveRecord::Migration[6.0]
  def change
	 create_table :user_profile_images do |t|
		t.bigint :user_id
		t.string :ext
		t.string :mime_type
		t.string :etag
		t.timestamps
    end
  end
end
