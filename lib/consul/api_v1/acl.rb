module Consul
  module APIv1
    class ACL < EndpointCategory
      define_endpoint :put, 'create'
      define_endpoint :put, 'update'
      define_endpoint :put, 'destroy/:id'
      define_endpoint :get, 'info/:id'
      define_endpoint :put, 'clone/:id'
      define_endpoint :get, 'list'
    end
  end
end
