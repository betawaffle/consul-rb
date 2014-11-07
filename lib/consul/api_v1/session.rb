module Consul
  module APIv1
    class Session < EndpointCategory
      define_endpoint :put, 'create', supports: %w[dc]
      define_endpoint :put, 'destroy/:session', supports: %w[dc]
      define_endpoint :get, 'info/:session', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'node/:node', supports: %w[blocking consistency_modes dc]
      define_endpoint :get, 'list', supports: %w[blocking consistency_modes dc]

      def handle_response(res)
        if res.body == 'null'
          []
        else
          super
        end
      end
    end
  end
end
