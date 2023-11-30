class AddDataProcessingToPackPuzzle < ActiveRecord::Migration
  def change
    add_column :pack_puzzles, :data_processing, :boolean, default: false
  end
end
