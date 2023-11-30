module UrlHelper

  def self.host_constraint scope

    Rails.application.config.version_hosts[Rails.env][scope.to_s]

  end

  def self.get_host scope
    Rails.application.config.version_hosts[Rails.env][scope.to_s]
  end

  def self.get_url scope, request

    port = request.port == 80 ? '' : ':' + request.port.to_s
    host = UrlHelper.get_host(scope)

    return host == true ? "/#{scope}" : '//' + host + port

  end

  def self.get_version host
    versions = Rails.application.config.version_hosts
    versions.each do |k, v|
      v.each do |kk, vv|
        hosts = vv.map do |hk, h|
          h
        end
        return k.to_sym if host.match(Regexp.new("(#{hosts.join('|')})"))
      end
    end
    return :bonza
  end

end