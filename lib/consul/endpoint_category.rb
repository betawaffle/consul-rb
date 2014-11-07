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

        allowed_params = []

        if params = options[:params]
          params.each { |param| allowed_params << param.to_sym }
        end

        if features = options[:supports]
          features.each do |feature|
            case feature = feature.to_sym
            when :blocking
              allowed_params.push :index, :wait
            when :consistency_modes
              allowed_params.push :consistent, :stale
            when :dc, :token
              allowed_params.push feature
            else
              raise ArgumentError, "#{feature} is not a known feature"
            end
          end
        end

        args << 'options = nil'
        path = parts.join('/')
        file = __FILE__
        line = __LINE__ + 2
        code = <<-rb
          def #{name}(#{args.join(', ')})
            options = Options.new(options) do |o|
              o.method = :#{method}
              o.restrict_params! #{allowed_params.inspect}
            end
            new_request "#{base_path}/#{path}", options
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

    def handle_response(res)
      case res.headers['Content-Type']
      when MIME_JSON
        JSON.parse(res.body) rescue nil
      end
    end

    def new_request(path, options)
      req = ::Typhoeus::Request.new("#{@base_url}#{path}", options.to_hash)
      req.on_complete { |res| handle_response(res) }
      req.on_failure { |res| raise APIError.new(res) } unless options.raise_error == false
      req
    end
  end # EndpointCategory
end
