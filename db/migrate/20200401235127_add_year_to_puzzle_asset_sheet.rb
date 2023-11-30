class AddYearToPuzzleAssetSheet < ActiveRecord::Migration
  def change
    add_column :puzzle_asset_sheets, :year, :integer, null: true
  end
end
