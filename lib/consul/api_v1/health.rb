module Consul
  module APIv1
    class Health < Category
      define_endpoint :get, 'node/:node', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'checks/:service', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'service/:service', params: %w[passing tag], supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'state/:state', supports: %w[blocking consistency_modes dc]
    end

    CATEGORIES[:health] = Health
  end
end
