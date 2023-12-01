class Admin::JobsController < Admin::ApplicationController

  before_action :admin_auth_level_only!

  def index
    @jobs = Delayed::Job.all.reorder('id')
  end

end