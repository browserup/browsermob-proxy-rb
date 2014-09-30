module BrowserMob
  module Proxy

    class Client
      attr_reader :host, :port

      def self.from(server_url, port = nil)
        # ActiveSupport may define Object#load, so we can't use MultiJson.respond_to? here.
        sm = MultiJson.singleton_methods.map { |e| e.to_sym }
        decode_method = sm.include?(:load) ? :load : :decode

        new_proxy_url = URI.join(server_url, "proxy")
        new_proxy_url.query = "port=#{port}" if port

        port = MultiJson.send(decode_method,
          RestClient.post(new_proxy_url.to_s, '')
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

      #
      # @example
      #   client.new_har("page-name")
      #   client.new_har("page-name", :capture_headers => true)
      #   client.new_har(:capture_headers => true)
      #   client.new_har(:capture_content => true)
      #   client.new_har(:capture_binary_content => true)
      #

      def new_har(ref = nil, opts = {})
        if opts.empty? && ref.kind_of?(Hash)
          opts = ref
          ref = nil
        end

        params = {}

        params[:initialPageRef] = ref if ref
        params[:captureHeaders] = true if opts[:capture_headers]
        params[:captureContent] = true if opts[:capture_content]

        if opts[:capture_binary_content]
          params[:captureContent] = true
          params[:captureBinaryContent] = true
        end

        previous = @resource["har"].put params
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

      #
      # Set a list of URL regexes to whitelist
      #
      # Note that passed regexp/string should match string as a whole
      # (i.e. if /example\.com/ is whitelisted "http://www.example.com" won't be allowed
      # though if /.+example\.com" is whitelisted "http://www.example.com" will be allowed)
      #
      # @param regexp [Regexp, String, Array<String, Regexp>]   a regexp, string or an array of regexps/strings that urls should match to
      # @param status_code [Integer]    the HTTP status code to return for URLs that do not match the whitelist
      #

      def whitelist(regexp, status_code)
        regex = Array(regexp).map { |rx| Regexp === rx ? rx.source : rx.to_s }.join(',')
        @resource['whitelist'].put :regex => regex, :status => status_code
      end

      def clear_whitelist
        @resource['whitelist'].delete
      end

      def blacklist(regexp, status_code)
        regex = Regexp === regexp ? regexp.source : regexp.to_s
        @resource['blacklist'].put :regex => regex, :status => status_code
      end

      def clear_blacklist
        @resource['blacklist'].delete
      end

      def rewrite(match_regex, replace)
        regex = Regexp === match_regex ? match_regex.source : match_regex.to_s
        @resource['rewrite'].put :matchRegex => regex, :replace => replace
      end

      def clear_rewrites
        @resource['rewrite'].delete
      end

      def header(hash)
        @resource['headers'].post hash.to_json, :content_type => "application/json"
      end
      alias_method :headers, :header

      def basic_authentication(domain, username, password)
        data = { username: username, password: password }
        @resource["auth/basic/#{domain}"].post data.to_json, :content_type => "application/json"
      end

      TIMEOUTS = {
        request: :requestTimeout,
        read: :readTimeout,
        connection: :connectionTimeout,
        dns_cache: :dnsCacheTimeout
      }

      #
      # Specify timeouts that will be used by a proxy
      # (see README of browsermob-proxy itself for more info about what they mean)
      #
      # @param timeouts [Hash]   options that specify desired timeouts (in seconds)
      # @option timeouts [Numeric] :request    request timeout
      # @option timeouts [Numeric] :read       read timeout
      # @option timeouts [Numeric] :connection connection timeout
      # @option timeouts [Numeric] :dns_cache  dns cache timeout
      #

      def timeouts(timeouts = {})
        params = {}

        timeouts.each do |key, value|
          unless TIMEOUTS.member?(key)
            raise ArgumentError, "invalid key: #{key.inspect}, should belong to: #{TIMEOUTS.keys.inspect}"
          end

          params[TIMEOUTS[key]] = (value * 1000).to_i
        end

        @resource['timeout'].put params
      end

      #
      # Override normal DNS lookups (remap the given hosts with the associated IP address).
      #
      # Each invocation of the method will add given hosts to existing BrowserMob's DNS cache
      # instead of overriding it.
      #
      # @example
      #   remap_dns_hosts('example.com' => '1.2.3.4')
      # @param hash [Hash] a hash with domains as keys and IPs as values
      #

      def remap_dns_hosts(hash)
        @resource['hosts'].post hash.to_json, :content_type => 'application/json'
      end

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

      def request_interceptor=(data)
        @resource['interceptor/request'].post data, :content_type => "text/plain"
      end

      def response_interceptor=(data)
        @resource['interceptor/response'].post data, :content_type => "text/plain"
      end
    end # Client

  end # Proxy
end # BrowserMob
