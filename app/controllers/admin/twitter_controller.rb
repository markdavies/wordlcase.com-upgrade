class Admin::TwitterController < Admin::ApplicationController

    def auth

        config = AppConfig.get
        config.twitter_access_token = request.env['omniauth.auth'][:credentials][:token]
        config.twitter_access_token_secret = request.env['omniauth.auth'][:credentials][:secret]

        config.save

    end

end