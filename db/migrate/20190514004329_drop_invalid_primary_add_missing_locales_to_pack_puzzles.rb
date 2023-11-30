class DropInvalidPrimaryAddMissingLocalesToPackPuzzles < ActiveRecord::Migration
  def change
    add_column :pack_puzzles, :status_missing_locales, :boolean, default: false
    remove_column :pack_puzzles, :status_invalid_primary
  end
end
