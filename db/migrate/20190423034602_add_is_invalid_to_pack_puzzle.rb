class AddIsInvalidToPackPuzzle < ActiveRecord::Migration
  def change
    add_column :pack_puzzles, :status_invalid, :boolean, default: false
  end
end
