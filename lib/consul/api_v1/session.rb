module Consul
  module APIv1
    class Session < EndpointCategory
      define_endpoint :put, 'create', supports: %w[dc]
      define_endpoint :put, 'destroy/:session', supports: %w[dc]
      define_endpoint :get, 'info/:session', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'node/:node', as: 'list_for_node', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'list', as: 'list', supports: %w[blocking consistency_modes dc]
    end
  end
end
