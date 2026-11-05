class AddFiltersToExports < ActiveRecord::Migration[8.1]
  def change
    add_column :exports, :filters, :jsonb, null: false, default: {}
  end
end
