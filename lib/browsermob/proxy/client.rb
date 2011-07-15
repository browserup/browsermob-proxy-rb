module BrowserMob
  module Proxy

    class Client
      def self.from(server_url)
        port = JSON.parse(
          RestClient.post(URI.join(server_url, "proxy").to_s, '')
        ).fetch('port')

        uri = URI.parse(File.join(server_url, "proxy", port.to_s))
        resource = RestClient::Resource.new(uri.to_s)

        Client.new resource, uri.host, port
      end

      def initialize(resource, host, port)
        @resource = resource
        @host = host
        @port = port
      end

      def new_har(initial_page_ref)
        previous = @resource["har"].put :initialPageRef => initial_page_ref
        HAR::Archive.from_string(previous) unless previous.empty?
      end

      def har
        HAR::Archive.from_string @resource["har"].get
      end

      def selenium_proxy
        require 'selenium-webdriver' unless defined?(Selenium)
        Selenium::WebDriver::Proxy.new(:http => "#{@host}:#{@port}")
      end

      def close
        @resource.delete
      end
    end

  end
end