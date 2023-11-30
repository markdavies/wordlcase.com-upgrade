class AddDraftPackParcelToPack < ActiveRecord::Migration
  def change
    add_attachment :packs, :draft_pack_parcel
  end
end
