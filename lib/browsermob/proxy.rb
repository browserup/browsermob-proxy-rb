require 'restclient'
require 'json'
require 'har'

require 'browsermob/proxy/client'

module BrowserMob
  module Proxy

    def self.create(server_url)
      port = JSON.parse(
        RestClient.post(URI.join(server_url, "proxy").to_s, '')
      ).fetch('port')

      uri = URI.parse(File.join(server_url, "proxy", port.to_s))
      resource = RestClient::Resource.new(uri.to_s)

      Client.new resource, uri.host, port
    end

  end # Proxy
end # BrowserMob

