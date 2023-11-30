class AddTestedEnglishToPack < ActiveRecord::Migration
  def change
    add_column :packs, :tested_primary, :boolean, default: false
  end
end
