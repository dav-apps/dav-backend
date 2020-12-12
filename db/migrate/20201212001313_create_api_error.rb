class CreateApiError < ActiveRecord::Migration[6.0]
  def change
	 create_table :api_errors do |t|
		t.bigint :api_id
		t.integer :code
		t.string :message
    end
  end
end
