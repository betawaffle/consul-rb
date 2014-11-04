require 'typhoeus'
require 'json'

module Consul
  DEFAULT_BASE_URL = ENV.fetch('CONSUL_URL', 'http://127.0.0.1:8500').freeze

  module APIv1
    MIME_JSON  = 'application/json'.freeze
    CATEGORIES = {}

    def self.each_category(&block)
      CATEGORIES.each_pair(&block)
    end

    class Category
      class << self
        private

        def path_component(value = nil)
          if value
            @path_component = value
          else
            @path_component ||= self.name.split('::').last.downcase
          end
        end

        def define_endpoint(method, path, options = {})
          parts, args = split_path(path)
          name = options[:as] || guess_name(method, path, parts, args)

          optional_params = options[:params] || []
          optional_params.map! { |k| k.to_sym }

          features = options[:supports] || []
          features.map! { |k| k.to_sym }

          args << 'options = {}'
          path = parts.join('/')
          file = __FILE__
          line = __LINE__ + 2
          code = <<-rb
            def #{name}(#{args.join(', ')})
              extract_params(options, #{optional_params.inspect})
              extract_feature_params(options, #{features.inspect})
              new_request(:#{method}, "/v1/#{path_component}/#{path}", options)
            end
          rb

          class_eval code, file, line
        end # define_endpoint

        def guess_name(method, path, parts, args)
          action = method

          # number of static parts
          case parts.size - args.size
          when 0 # action = method
          when 1
            if args.size > 0 || method == :put
              action = parts[0]
            else
              subject = parts[0]
            end
          when 2
            action = parts[1]
            subject = parts[0]
          else
            raise "unable to guess name for endpoint /v1/#{path_component}/#{path}"
          end

          action = action.to_s.sub(/-/, '_')

          if subject
            "#{action}_#{subject}"
          else
            "#{action}"
          end
        end # guess_name

        def split_path(path)
          args  = []
          parts = []
          path.split('/').each do |part|
            if part[0] == ':'
              arg = part[1..-1].to_sym
              args  << arg
              parts << "#\{#{arg}}"
            else
              parts << part
            end
          end

          return parts, args
        end
      end # class << Category

      def initialize(base_url = DEFAULT_BASE_URL, options = {})
        @base_url = base_url.to_s.chomp('/')
        @token = options[:token]
      end

      private

      def extract_params(options, optional_params)
        params = options[:params] || {}
        optional_params.each do |key|
          if val = options.delete(key)
            params[key] = val
          end
        end

        options[:params] = params
      end

      def extract_feature_params(options, features)
        params = options[:params] || {}
        features.each do |feature|
          case feature
          when :blocking
            index = options.delete(:index)
            wait  = options.delete(:wait)

            # wait has no meaning without index
            if index
              params[:index] = index
              params[:wait] = wait if wait
            end
          when :consistency_modes
            case mode = options.delete(:consistency_mode)
            when nil, :default, 'default'
            when :consistent, 'consistent'
              params[:consistent] = true
            when :stale, 'stale'
              params[:stale] = true
            else
              raise ArgumentError, "#{mode} is not a valid consistency mode"
            end
          when :dc
            if value = options.delete(:dc)
              params[:dc] = value
            end
          when :token
            if value = options.delete(:token) { @token }
              params[:token] = value
            end
          else
            raise ArgumentError, "#{feature} is not a known feature"
          end
        end # features.each

        options[:params] = params
      end # extract_feature_params

      def new_request(method, path, options)
        options[:method] = method

        req = ::Typhoeus::Request.new("#{@base_url}#{path}", options)
        req.on_complete do |res|
          next res unless res.headers['Content-Type'] == MIME_JSON
          JSON.parse(res.body) rescue res
        end

        req
      end
    end # Category
  end # APIv1
end # Consul

require 'consul/api_v1/kv'
require 'consul/api_v1/agent'
require 'consul/api_v1/catalog'
require 'consul/api_v1/health'
require 'consul/api_v1/session'
require 'consul/api_v1/acl'
require 'consul/api_v1/event'
require 'consul/api_v1/status'
