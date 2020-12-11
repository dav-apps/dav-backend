class CreateTablePropertyType < ActiveRecord::Migration[6.0]
  def change
	 create_table :table_property_types do |t|
		t.bigint :table_id
		t.string :name
		t.integer :data_type, default: 0
    end
  end
end
