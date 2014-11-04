module Consul
  class Session
    def self.create(api, name, checks, opts = nil)
      hash = {}
      hash['Name'] = name if name
      hash['Checks'] = checks if checks

      if opts
        opts = opts.dup

        if node = opts.delete(:node)
          hash['Node'] = node
        end

        if lock_delay = opts.delete(:lock_delay)
          hash['LockDelay'] = lock_delay
        end

        if dc = opts.delete(:dc)
          params = { dc: dc }
        end
      else
        opts = {}
      end

      opts[:body] = hash.to_json

      res = api.new_request(:put, '/v1/session/create', params, opts)
      res.on_success do |res|
        case hash = res.handled_response
        when Hash
          return new(api, hash['ID'], dc)
        end
      end

      res.run
    end

    def self.list(api, opts = nil)
      if opts
        opts = opts.dup

        if node = opts.delete(:node)
          sub_path = "node/#{node}"
        end

        if dc = opts.delete(:dc)
          params = { dc: dc }
        end
      end

      sub_path ||= 'list'

      req = new_request(api, :get, sub_path, params, opts)
      req.on_success do |res|
        case arr = res.handled_response
        when Array
          arr.map { |hash| new(api, hash, dc) }
        end

        arr
      end

      req.run
    end

    attr_reader :id

    def initialize(api, id_or_hash, dc = nil)
      @api = api
      @dc  = dc

      case id_or_hash
      when String
        @id = id_or_hash
      when Hash
        from_hash(id_or_hash)
      else
        raise TypeError, "expected String or Hash, got #{id_or_hash.class}"
      end
    end

    def get_info
      req = new_request(:get, "info/#{@id}", params)
      req.on_success do |res|
        case hash = res.handled_response
        when Hash
          from_hash(hash)
        end

        hash
      end

      req.run
    end

    def destroy
      new_request(:put, "destroy/#{@id}", params).run.success?
    end

    private

    def self.new_request(api, method, sub_path, params = nil, opts = nil)
      api.new_request(method, "/v1/session/#{sub_path}", params, opts)
    end

    def new_request(method, sub_path, params = nil, opts = nil)
      @api.new_request(method, "/v1/session/#{sub_path}", params, opts)
    end

    def from_hash(hash)
      if index = hash['CreateIndex']
        @index = index
        @id = hash['ID']
        @node = hash['Node']
        @checks = hash['Checks']
        @lock_delay = hash['LockDelay']
      end
    end

    def params
      { dc: @dc } if @dc
    end
  end
end
