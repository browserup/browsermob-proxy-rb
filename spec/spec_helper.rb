require 'browsermob/proxy'
require 'selenium-webdriver'
require 'browsermob/proxy/webdriver_listener'

RestClient.log = STDOUT

module BrowserMob
  module Proxy
    module SpecHelper
      def server
        $_bm_server ||= Server.new(File.join(home, "bin", "browsermob-proxy"), :log => true).start
      end

      def new_proxy
        server.create_proxy
      end

      def home
        ENV['BROWSERMOB_PROXY_HOME'] or raise "BROWSERMOB_PROXY_HOME not set"
      end

      def fixture(name)
        File.read(fixture_path(name))
      end

      def url_for(page)
        "file://#{fixture_path page}"
      end

      def fixture_path(name)
        File.join(File.expand_path("../", __FILE__), "fixtures", name)
      end

    end
  end
end


RSpec.configure do |c|
  c.include(BrowserMob::Proxy::SpecHelper)
  c.after(:suite) { $_bm_server.stop if $_bm_server }
end

if ENV['TRAVIS']
  ENV['DISPLAY'] = ":99"
end