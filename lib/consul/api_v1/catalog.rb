module Consul
  module APIv1
    class Catalog < EndpointCategory
      define_endpoint :put, 'register'
      define_endpoint :put, 'deregister'
      define_endpoint :get, 'datacenters'
      define_endpoint :get, 'nodes', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'services', supports: %w[blocking consistency_modes dc]

      # auto-name is not ideal for these two
      define_endpoint :get, 'service/:service', params: %w[tag], supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'node/:node', supports: %w[blocking consistency_modes dc]
    end
  end
end
