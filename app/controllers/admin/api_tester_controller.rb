class Admin::ApiTesterController < Admin::ApplicationController

  include AdminHelper

  def index
    @api_host_data  = UrlHelper.get_url :data, request
  end

end