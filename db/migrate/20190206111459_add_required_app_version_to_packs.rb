class AddRequiredAppVersionToPacks < ActiveRecord::Migration
  def change
    add_column :packs, :required_app_version, :integer, default: 0
  end
end
