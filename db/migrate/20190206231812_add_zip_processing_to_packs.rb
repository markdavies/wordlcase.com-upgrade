class AddZipProcessingToPacks < ActiveRecord::Migration
  def change
    add_column :packs, :draft_parcel_processing, :boolean, default: false
    add_column :packs, :parcel_processing, :boolean, default: false
  end
end
