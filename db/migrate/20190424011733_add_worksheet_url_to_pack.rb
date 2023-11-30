class AddWorksheetUrlToPack < ActiveRecord::Migration
  def change
    add_column :packs, :worksheet_url, :string
  end
end
