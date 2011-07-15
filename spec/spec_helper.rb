require 'browsermob/proxy'
require 'selenium-webdriver'

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
        File.read(File.join(File.expand_path("../", __FILE__), "fixtures", name))
      end

    end
  end
end


RSpec.configure do |c|
  c.include(BrowserMob::Proxy::SpecHelper)
  c.after(:suite) { $_bm_server.stop if $_bm_server }
end