module Consul
  class KV
    def initialize(api, key)
      @api = api
      @key = key
    end

    def get(params = nil, opts = nil)
      new_request :get, params, opts
    end

    def get_all_keys(opts = nil)
      params = { keys: true }

      get(params, opts)
    end

    def get_keys(opts = nil)
      params = { keys: true, separator: '/' }

      get(params, opts)
    end

    def get_value(opts = nil)
      params = { raw: true }

      get(params, opts)
    end

    def put(value, params = nil, opts = nil)
      if opts
        opts = opts.merge(body: value)
      else
        opts = { body: value }
      end

      new_request :put, params, opts
    end

    def delete(params = nil, opts = nil)
      new_request :delete, params, opts
    end

    private

    def new_request(method, params = nil, opts = nil)
      @api.new_request(method, "/v1/kv/#{@key}", params, opts)
    end
  end
end
