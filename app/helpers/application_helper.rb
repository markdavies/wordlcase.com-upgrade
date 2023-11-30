module ApplicationHelper

  def site_asset_path

    c = Rails.application.config
    host = c.action_controller.asset_host || ''
    prefix = c.assets.prefix || ''

    host + prefix + '/'

  end

  def valid_link link
    u = URI.parse(link) rescue false
    link = 'http://'+link if(!u || !u.scheme)
    link
  end

  def data_json data

    return {} if data.nil?
    parsed = begin
      JSON.parse(data)
    rescue JSON::ParserError
      {}
    end
    parsed

  end

end
