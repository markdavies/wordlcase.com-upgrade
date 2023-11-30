class AddPublishedPuzzleToPackPuzzle < ActiveRecord::Migration
  def change
    add_column :pack_puzzles, :puzzle_published, :text
  end
end
