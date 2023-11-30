class RemoveStatesFromAppConfig < ActiveRecord::Migration
  def change
    remove_column :app_configs, :all_embedded_packs_state, :string
    remove_column :app_configs, :embedded_images_state, :string
  end
end
