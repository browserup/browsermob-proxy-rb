module BrowserMob
  module Proxy

    class Client
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