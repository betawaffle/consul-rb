module Consul
  class Session
    JSON_MAPPING = {
      :name       => 'Name',
      :node       => 'Node',
      :checks     => 'Checks',
      :lock_delay => 'LockDelay'
    }

    class << self
      def create(api, options = nil)
        options = Options.new(options) do |o|
          o.body = json_for_create(o)
        end

        req = api.session.create(options)
        req.on_success do |res|
          new api, res.handled_response['ID'], options.dc
        end

        req.run.handled_response
      end

      def list(api, options = nil)
        node = nil
        options = Options.new(options) do |o|
          node = o.delete(:node)
        end

        if node
          req = api.session.list_for_node(node, options)
        else
          req = api.session.list(options)
        end

        req.on_success do |res|
          case arr = res.handled_response
          when Array
            arr.map { |info| new api, info, options.dc }
          when nil
            []
          end
        end

        req.run.handled_response
      end

      private

      def json_for_create(options)
        hash = {}

        JSON_MAPPING.each_pair do |option, field|
          next unless val = options.delete(option)
          hash[field] = val
        end

        hash.to_json
      end
    end

    attr_reader :id, :create_index
    attr_reader *JSON_MAPPING.keys

    def initialize(api, id_or_info, dc = nil)
      @api = api
      @dc  = dc.freeze

      case id_or_info
      when String
        @id = id_or_info.freeze
        get_info
      when Hash
        @id = id_or_info['ID'].freeze
        update_info(id_or_info)
      else
        raise ArgumentError, "expected id or info hash, got #{id_or_info.class}"
      end
    end

    def destroy(options = nil)
      return if @dead # don't waste time and bandwidth if we already know
      options = Options.new(options) do |o|
        o.dc = @dc
      end

      @api.session.destroy(@id, options).run.success?
    end

    def get_info(options = nil)
      return if @dead
      options = Options.new(options) do |o|
        o.dc = @dc
      end

      req = @api.session.info(@id, options)
      req.on_success do |res|
        case arr = res.handled_response
        when Array
          raise 'unexpected response' unless arr.size < 2

          if arr.size == 1
            update_info(arr.first)
          else # 0
            @dead = true
            update_info({}) # this is just so easy
          end

          arr.first
        end
      end

      res = req.run
      res.handled_response
    end

    def inspect
      if @dead
        tail = 'dead'
      else
        tail = JSON_MAPPING.each_key.map { |k| %[@#{k}=#{instance_variable_get(:"@#{k}").inspect}] }.join(', ')
      end

      %[#<#{self.class} #{@id} #{tail}>]
    end

    private

    def update_info(info)
      unless @dead || info['ID'] == @id
        raise "session id mismatch, #{info['ID'].inspect} != #{@id.inspect}"
      end

      @create_index = info['CreateIndex']

      JSON_MAPPING.each_pair do |var, field|
        instance_variable_set(:"@#{var}", info[field].freeze)
      end
    end
  end # Session
end
