class CreateCollection < ActiveRecord::Migration[6.0]
  def change
	 create_table :collections do |t|
		t.bigint :table_id
		t.string :name
		t.timestamps
    end
  end
end
