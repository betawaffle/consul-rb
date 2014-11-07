module Consul
  class Session
    JSON_MAPPING = {
      :name       => 'Name',
      :node       => 'Node',
      :checks     => 'Checks',
      :lock_delay => 'LockDelay'
    }

    class << self
      def create(api, options = {})
        options[:body] = json_for_create(options)

        req = api.session.create(options)
        req.on_success do |res|
          if params = options[:params]
            dc = params[:dc]
          end
          new api, res.handled_response['ID'], dc
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

    attr_reader :id, :name, :node, :checks, :lock_delay
    attr_reader :create_index

    def initialize(api, id, dc = nil)
      @api = api
      @id  = id.freeze
      @dc  = dc.freeze

      get_info
    end

    def destroy(options = {})
      return if @dead # don't waste time and bandwidth if we already know
      options[:dc] = @dc

      @api.session.destroy(@id, options).run.success?
    end

    def get_info(options = {})
      return if @dead
      options[:dc] = @dc

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
        when res
          next # nil
        end

        arr
      end

      res = req.run
      res.handled_response unless @dead
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

    def update_info(hash)
      unless @dead || hash['ID'] == @id
        raise "session id mismatch, #{hash['ID'].inspect} != #{@id.inspect}"
      end

      @create_index = hash['CreateIndex']

      JSON_MAPPING.each_pair do |var, field|
        instance_variable_set(:"@#{var}", hash[field].freeze)
      end
    end
  end # Session
end
