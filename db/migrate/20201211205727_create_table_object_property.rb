class CreateTableObjectProperty < ActiveRecord::Migration[6.0]
  def change
	 create_table :table_object_properties do |t|
		t.bigint :table_object_id
		t.string :name
		t.text :value
    end
  end
end
