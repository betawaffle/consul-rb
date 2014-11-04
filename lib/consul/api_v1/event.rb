module Consul
  module APIv1
    class Event < Category
      define_endpoint :put, 'fire/:name', params: %w[node service tag], supports: %w[dc]
      define_endpoint :get, 'list', params: %w[name], supports: %w[blocking]
    end

    CATEGORIES[:event] = Event
  end
end
