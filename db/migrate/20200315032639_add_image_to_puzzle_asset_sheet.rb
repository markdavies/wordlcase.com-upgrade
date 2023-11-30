class AddImageToPuzzleAssetSheet < ActiveRecord::Migration
  def change
    add_attachment :puzzle_asset_sheets, :image
    add_column :puzzle_asset_sheets, :pack_type, :string
    add_column :puzzle_asset_sheets, :position, :integer
  end
end
