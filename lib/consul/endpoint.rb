module Consul
  class Endpoint
    def initialize(api, path, methods, opts = nil)
      @api = api
    end
  end

  # endpoint '/v1/session/create', [ :put ]
  # endpoint '/v1/session/destroy/:id', [ :put ]
end
