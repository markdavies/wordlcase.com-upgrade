class AddGamePositionToPuzzle < ActiveRecord::Migration
  def change
    add_column :pack_puzzles, :game_position, :integer, null: true
  end
end
