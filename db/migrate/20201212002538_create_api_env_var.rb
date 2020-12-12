class CreateApiEnvVar < ActiveRecord::Migration[6.0]
  def change
	 create_table :api_env_vars do |t|
		t.bigint :api_id
		t.string :name
		t.string :value
		t.string :class_name
    end
  end
end
