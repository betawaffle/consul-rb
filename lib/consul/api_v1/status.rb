module Consul
  module APIv1
    class Status < EndpointCategory
      define_endpoint :get, 'leader'
      define_endpoint :get, 'peers'
    end
  end
end
