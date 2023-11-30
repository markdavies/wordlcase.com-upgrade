class AddStaleSpriteSheetToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :sprite_sheet_status, :string, default: 'fresh'
  end
end
