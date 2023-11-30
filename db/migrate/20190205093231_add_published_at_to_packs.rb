class AddPublishedAtToPacks < ActiveRecord::Migration
  def change
    add_column :packs, :published_at, :datetime
  end
end
