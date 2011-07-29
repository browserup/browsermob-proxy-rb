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

      def initialize(client)
        @client = client
        @hars = []
      end

      def reset
        @hars.clear
      end

      def before_navigate_to(url)
        save_har unless @hars.empty? # first request
        @client.new_har("navigate-to-#{url}")
      end

      def before_navigate_back(driver = nil) # post selenium-webdriver 2.3
        name = "navigate-back"
        name << "-from-#{driver.current_url}" if driver

        @client.new_page name
      end

      def before_navigate_forward(driver = nil) # post selenium-webdriver 2.3
        name = "navigate-forward"
        name << "-from-#{driver.current_url}" if driver

        @client.new_page name
      end

      def before_click(element)
        name = "click-element-#{identifier_for element}"
        @client.new_page name
      end

      def before_quit
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