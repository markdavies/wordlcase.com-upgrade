class AddSheetsZipToAppConfig < ActiveRecord::Migration
  def change
    add_attachment :app_configs, :puzzle_sheets
  end
end
