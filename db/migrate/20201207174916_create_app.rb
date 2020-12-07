class CreateApp < ActiveRecord::Migration[6.0]
  def change
	 create_table :apps do |t|
		t.integer :dev_id
		t.string :name
		t.string :description
		t.boolean :published, default: false
		t.string :web_link
		t.string :google_play_link
		t.string :microsoft_store_link
    end
  end
end
