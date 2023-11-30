class AddImageQualityToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :image_quality, :integer, default: 80
  end
end
