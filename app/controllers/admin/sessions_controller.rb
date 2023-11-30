class Admin::SessionsController < Devise::SessionsController 

  skip_before_filter :redirect_old_ie
  skip_before_filter :collect_categories
  skip_before_filter :set_i18n_locale
  skip_before_filter :force_trailing_slash
  skip_before_filter :country_redirect
  
  layout 'admin'

  private

  def after_sign_out_path_for resource_or_scope
    admin_root_path
  end

end
