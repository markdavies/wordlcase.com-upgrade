class CreatePuzzleAssetSheets < ActiveRecord::Migration
  def change
    create_table :puzzle_asset_sheets do |t|
      t.timestamps null: false
    end
  end
end
