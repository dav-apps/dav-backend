class CreateRedisTableObjectOperation < ActiveRecord::Migration[6.1]
  def change
    create_table :redis_table_object_operations do |t|
		t.string :table_object_uuid
		t.string :operation
      t.timestamps
    end
  end
end
