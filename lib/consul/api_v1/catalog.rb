module Consul
  module APIv1
    class Catalog < EndpointCategory
      define_endpoint :put, 'register'
      define_endpoint :put, 'deregister'
      define_endpoint :get, 'datacenters'
      define_endpoint :get, 'nodes', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'services', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'service/:service', as: 'get_nodes_with_service', params: %w[tag], supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'node/:node', as: 'get_services_on_node', supports: %w[blocking consistency_modes dc]
    end
  end
end
