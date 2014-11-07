module Consul
  class EndpointCategory
    class << self
      attr_reader :base_path

      def inherited(sub)
        case sub.name
        when /^Consul::API(v\d+)::(\w+)$/
          sub.instance_exec($1.to_sym, $2.downcase.to_sym) do |version, path|
            @api_version = version
            @path_component = path
            @base_path = "/#{version}/#{path}".freeze

            mod = ::Consul.const_get(:"API#{version}")
            mod::CATEGORIES[path] = sub
          end
        else
          raise "unexpected EndpointCategory subclass #{sub}"
        end
      end

      private

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
            new_request(:#{method}, "#{base_path}/#{path}", options)
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
          raise "unable to guess method name for endpoint #{base_path}/#{path}"
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
    end # class << EndpointCategory

    def initialize(base_url = DEFAULT_BASE_URL, options = {})
      @base_url = base_url.to_s.chomp('/')
      @token = options[:token]
    end

    def inspect
      %[#<#{self.class} #{@base_url}>]
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

    def handle_response(res)
      case res.headers['Content-Type']
      when MIME_JSON
        JSON.parse(res.body) rescue nil
      end
    end

    def new_request(method, path, options)
      options[:method] = method
      raise_error = options.delete(:raise_error)

      req = ::Typhoeus::Request.new("#{@base_url}#{path}", options)
      req.on_complete { |res| handle_response(res) }
      req.on_failure { |res| raise APIError.new(res) } unless raise_error == false
      req
    end
  end # EndpointCategory
end
