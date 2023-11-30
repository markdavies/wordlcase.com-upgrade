class AddTwitterAuthToAppConfig < ActiveRecord::Migration
  def change
    add_column :app_configs, :twitter_access_token, :text
    add_column :app_configs, :twitter_access_token_secret, :text
  end
end
