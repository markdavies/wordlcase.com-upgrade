class DropEmbeddedPacksAndImages < ActiveRecord::Migration
  def change
    remove_attachment :app_configs, :all_embedded_packs
    remove_attachment :app_configs, :embedded_images
    remove_column :packs, :embedded
  end
end
