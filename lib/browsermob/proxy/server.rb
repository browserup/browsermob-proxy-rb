require 'childprocess'
require 'socket'

module BrowserMob
  module Proxy

    class Server
      attr_reader :port

      #
      # Create a new server instance
      #
      # @param       [String]  path    Path to the BrowserMob Proxy server executable
      # @param       [Hash]    opts    options to create the server with
      # @option opts [Integer] port    What port to start the server on
      # @option opts [Boolean] log     Show server output (server inherits stdout/stderr)
      # @option opts [Integer] timeout Seconds to wait for server to launch before timing out.
      #

      def initialize(path, opts = {})
        assert_executable path

        @path    = path
        @port    = Integer(opts[:port] || 8080)
        @timeout = Integer(opts[:timeout] || 10)
        @log     = !!opts[:log]

        @process = create_process
      end

      def start
        @process.start

        wait_for_startup

        pid = Process.pid
        at_exit { stop if Process.pid == pid }

        self
      end

      def url
        "http://localhost:#{port}"
      end

      def create_proxy(port = nil)
        Client.from url, port
      end

      def stop
        @process.stop if @process.alive?
      end

      private

      def create_process
        process        = ChildProcess.new(@path, "--port", @port.to_s)
        process.leader = true

        process.io.inherit! if @log

        process
      end

      def wait_for_startup
        end_time = Time.now + @timeout

        sleep 0.1 until (listening? && initialized?) || Time.now > end_time || !@process.alive?

        if Time.now > end_time
          raise TimeoutError, "timed out waiting for the server to start (rerun with :log => true to see process output)"
        end

        unless @process.alive?
          raise ServerDiedError, "unable to launch the server (rerun with :log => true to see process output)"
        end
      end

      def listening?
        TCPSocket.new("127.0.0.1", port).close
        true
      rescue
        false
      end

      def initialized?
        RestClient.get("#{url}/proxy")
        true
      rescue RestClient::Exception
        false
      end

      def assert_executable(path)
        unless File.exist?(path)
          raise Errno::ENOENT, path
        end

        unless File.executable?(path)
          raise Errno::EACCES, "not executable: #{path}"
        end
      end

      class TimeoutError < StandardError
      end

      class ServerDiedError < StandardError
      end

    end # Server
  end # Proxy
end # BrowserMob
