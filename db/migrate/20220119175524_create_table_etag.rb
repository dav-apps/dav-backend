class CreateTableEtag < ActiveRecord::Migration[6.0]
  def change
    create_table :table_etags do |t|
		t.bigint :user_id
		t.bigint :table_id
		t.string :etag
		t.timestamps
    end
  end
end
