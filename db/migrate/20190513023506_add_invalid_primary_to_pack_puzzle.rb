class AddInvalidPrimaryToPackPuzzle < ActiveRecord::Migration
  def change
    add_column :pack_puzzles, :status_invalid_primary, :boolean, default: false
  end
end
