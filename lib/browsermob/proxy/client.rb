module BrowserMob
  module Proxy

    class Client
      attr_reader :host, :port

      def self.from(server_url)
        # ActiveSupport may define Object#load, so we can't use MultiJson.respond_to? here.
        sm = MultiJson.singleton_methods.map { |e| e.to_sym }
        decode_method = sm.include?(:load) ? :load : :decode

        port = MultiJson.send(decode_method,
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

      def new_har(ref = nil)
        previous = @resource["har"].put :initialPageRef => ref
        HAR::Archive.from_string(previous) unless previous.empty?
      end

      def new_page(ref)
        @resource['har/pageRef'].put :pageRef => ref
      end

      def har
        HAR::Archive.from_string @resource["har"].get
      end

      def selenium_proxy(*protocols)
        require 'selenium-webdriver' unless defined?(Selenium)

        protocols += [:http] if protocols.empty?
        unless (protocols - [:http, :ssl, :ftp]).empty?
          raise "Invalid protocol specified.  Must be one of: :http, :ssl, or :ftp."
        end

        proxy_mapping = {}
        protocols.each { |proto| proxy_mapping[proto] = "#{@host}:#{@port}" }
        Selenium::WebDriver::Proxy.new(proxy_mapping)
      end

      def whitelist(regexp, status_code)
        regex = Regexp === regexp ? regexp.source : regexp.to_s
        @resource['whitelist'].put :regex => regex, :status => status_code
      end

      def blacklist(regexp, status_code)
        regex = Regexp === regexp ? regexp.source : regexp.to_s
        @resource['blacklist'].put :regex => regex, :status => status_code
      end

      def header(hash)
        @resource['headers'].post hash.to_json, :content_type => "application/json"
      end
      alias_method :headers, :header

      LIMITS = {
        :upstream_kbps   => 'upstreamKbps',
        :downstream_kbps => 'downstreamKbps',
        :latency         => 'latency'
      }

      def limit(opts)
        params = {}

        opts.each do |key, value|
          unless LIMITS.member?(key)
            raise ArgumentError, "invalid: #{key.inspect} (valid options: #{LIMITS.keys.inspect})"
          end

          params[LIMITS[key]] = Integer(value)
        end

        if params.empty?
          raise ArgumentError, "must specify one of #{LIMITS.keys.inspect}"
        end

        @resource['limit'].put params
      end

      def close
        @resource.delete
      end
    end # Client

  end # Proxy
end # BrowserMob