class CreateExceptionEvent < ActiveRecord::Migration[6.0]
  def change
	 create_table :exception_events do |t|
		t.bigint :app_id
		t.string :name
		t.string :message
		t.text :stack_trace
		t.string :app_version
		t.string :os_version
		t.string :device_family
		t.string :locale
		t.datetime :created_at, precision: 6, null: false
    end
  end
end
