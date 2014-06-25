require 'selenium/webdriver/support'

module BrowserMob
  module Proxy

    #
    # WebDriver event listener that assumes the following:
    #
    # driver.get - new HAR
    # driver.click - new page
    # driver.navigate.back - new page
    # driver.navigate.forward - new page
    #

    class WebDriverListener < Selenium::WebDriver::Support::AbstractEventListener
      attr_reader :hars

      def initialize(client, opts = {})
        @client = client
        @hars = []

        @new_har_opts = {}
        @new_har_opts[:capture_headers] = true if opts[:capture_headers]
        @new_har_opts[:capture_content] = true if opts[:capture_content]
        @new_har_opts[:capture_binary_content] = true if opts[:capture_binary_content]
      end

      def reset
        @hars.clear
      end

      def before_navigate_to(url, driver)
        save_har unless @hars.empty? # first request
        @client.new_har("navigate-to-#{url}", @new_har_opts)
      end

      def before_navigate_back(driver = nil)
        name = "navigate-back"
        name << "-from-#{driver.current_url}" if driver

        @client.new_page name
      end

      def before_navigate_forward(driver = nil)
        name = "navigate-forward"
        name << "-from-#{driver.current_url}" if driver

        @client.new_page name
      end

      def before_click(element, driver)
        name = "click-element-#{identifier_for element}"
        @client.new_page name
      end

      def before_quit(driver)
        save_har
      end

      private

      def save_har
        @hars << @client.har
      end

      def identifier_for(element)
        # can be ovverriden to provide more meaningful info
        element.ref
      end
    end
  end
end
