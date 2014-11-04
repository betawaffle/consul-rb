module Consul
  module APIv1
    class Status < Category
      define_endpoint :get, 'leader'
      define_endpoint :get, 'peers'
    end

    CATEGORIES[:status] = Status
  end
end
