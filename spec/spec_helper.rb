require 'browsermob/proxy'
require 'selenium-webdriver'
require 'browsermob/proxy/webdriver_listener'
require 'rack'

RestClient.log = STDOUT

module BrowserMob
  module Proxy
    module SpecHelper
      def self.httpd
        @httpd ||= HttpServer.new(SpecApp.new(Rack::File.new(fixture_dir)))
      end

      def self.fixture_dir
        @fixture_dir ||= File.join(File.expand_path("../", __FILE__), "fixtures")
      end

      def server
        $_bm_server ||= Server.new(
          File.join(home, "bin", "browsermob-proxy"),
          :port => Selenium::WebDriver::PortProber.above(3000),
          :log => true
        ).start
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
        SpecHelper.httpd.url_for(page)
      end

      def fixture_path(name)
        File.join(SpecHelper.fixture_dir, name)
      end

      class HttpServer
        def initialize(app)
          @port = Selenium::WebDriver::PortProber.above(3000)

          pid = fork do
            Rack::Server.new(:app => app, :Port => @port).start
          end

          at_exit { Process.kill 'TERM', pid }

          poller = Selenium::WebDriver::SocketPoller.new("0.0.0.0", @port, 10)

          unless poller.connected?
            raise "unable to start web server in 5 seconds"
          end
        end

        def url_for(page)
          # avoid default no-proxy rules on localhost
          host = ENV['TRAVIS'] ? Selenium::WebDriver::Platform.ip : '0.0.0.0'
          "http://#{host}:#{@port}/#{page}"
        end
      end

      class SpecApp
        def initialize(app)
          @app = app
        end

        def call(env)
          case env['REQUEST_PATH']
          when '/slow'
            sleep 0.1
            [200, {}, []]
          else
            @app.call(env)
          end
        end

      end
    end
  end
end

RSpec.configure do |c|
  c.include(BrowserMob::Proxy::SpecHelper)
  c.after(:suite) { $_bm_server.stop if $_bm_server }
end
