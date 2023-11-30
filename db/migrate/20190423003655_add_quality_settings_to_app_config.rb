class AddQualitySettingsToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :quality_threshold_1, :integer, default: 4
    add_column :app_configs, :quality_threshold_2, :integer, default: 6
  end
end
