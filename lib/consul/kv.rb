require 'base64'

module Consul
  class KV
    class << self
      def create(api, key, options = nil)
        res = api.kv.create(key, options).run
        return unless res.success? && res.response_body == 'true'

        if params = res.options[:params]
          dc = params[:dc]
        end

        kv = new api, key, dc
        kv.update_from_put_response(res)
        kv
      end
    end

    attr_reader :key, :value, :flags
    attr_reader :create_index, :update_index, :lock_index
    attr_reader :session

    def initialize(api, key, dc = nil)
      @api = api
      @key = key.freeze
      @dc  = dc.freeze
      @dir = key[-1] == '/'
    end

    def delete(options = nil)
      options = Options.new(options) do |o|
        o.dc = @dc
      end

      @api.kv.delete(@key, options).run.success?
    end

    def get(options = nil)
      options = Options.new(options) do |o|
        o.dc = @dc
      end

      req = @api.kv.get(@key, options)
      req.on_success do |res|
        case arr = res.handled_response
        when Array
          if arr.size == 1
            update_info(arr.first)
          else
            # TODO: This means they passed options we didn't really want them to, I think.
          end
        when nil
          next # nil
        end

        arr
      end

      req.run
      value
    end

    def get_value(options = nil)
      options = Options.new(options) do |o|
        o.dc = @dc
      end

      res = @api.kv.get_value(@key, options).run
      res.body if res.success?
    end

    def try_update(value, options = nil)
      unless String === value
        raise ArgumentError, "value must be a String, got #{value.class}"
      end

      unless index = @update_index || @create_index
        raise SafetyViolation, "current value of #{@key} should be read before attempting an update"
      end

      options = Options.new(options) do |o|
        o.dc = @dc
        o.cas = index
        o.body = value.freeze
      end

      result = nil

      req = @api.kv.put(@key, options)
      req.on_success do |res|
        result = !!update_from_put_response(res)
        res.handled_response
      end

      req.run
      result
    end

    def update(options = nil)
      unless block_given?
        raise ArgumentError, 'must be called with a block'
      end

      retries = nil
      options = Options.new(options) do |o|
        retries = o.retries || 0
        o.retries = nil
      end

      begin
        get
        new_value = yield value
        try_update(new_value, options) and return true
        retries -= 1
      end while retries > 0
    end

    def update_from_put_response(res)
      return unless res.response_body == 'true'

      options = res.options
      index   = res.headers['X-Consul-Index']

      @update_index   = index
      @create_index ||= index

      if params = options[:params]
        @flags = params[:flags]

        if session = params[:acquire]
          @session = Session.new(@api, session, @dc) unless @session && @session.id == session
          @lock_index = index
        end

        # TODO: Can this be passed in the same request? What happens?
        if params[:release]
          @session = nil
        end
      else
        @flags = 0
      end

      @value = options[:body].freeze
    end

    private

    def update_info(hash)
      unless hash['Key'] == @key
        raise "key mismatch, #{hash['Key'].inspect} != #{@key.inspect}"
      end

      @create_index = hash['CreateIndex']
      @update_index = hash['UpdateIndex']

      @lock_index = hash['LockIndex']

      if session = hash['Session']
        @session = Session.new(@api, session, @dc)
      else
        @session = nil
      end

      @flags = hash['Flags']

      if value = hash['Value']
        @value = Base64.decode64(value).freeze
      else
        @value = nil
      end
    end
  end
end
