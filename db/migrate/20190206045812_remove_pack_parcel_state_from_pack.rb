class RemovePackParcelStateFromPack < ActiveRecord::Migration
  def change
    remove_column :packs, :pack_parcel_state, :string
  end
end
