class IncreaseLimitOfCompiledApiEndpointsCode < ActiveRecord::Migration[6.1]
  def change
    change_column :compiled_api_endpoints, :code, :text, :limit => 4294967295
  end
end
