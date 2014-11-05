module Consul
  module APIv1
    class Agent < EndpointCategory
      define_endpoint :get, 'checks'
      define_endpoint :get, 'services'
      define_endpoint :get, 'members', params: %w[wan]
      define_endpoint :get, 'self'
      define_endpoint :get, 'join/:address', params: %w[wan]
      define_endpoint :get, 'force-leave/:node'
      define_endpoint :put, 'check/register'
      define_endpoint :get, 'check/deregister/:check_id' # get?
      define_endpoint :get, 'check/pass/:check_id', params: %w[note]
      define_endpoint :get, 'check/warn/:check_id', params: %w[note]
      define_endpoint :get, 'check/fail/:check_id', params: %w[note]
      define_endpoint :put, 'service/register'
      define_endpoint :get, 'service/deregister/:service_id' # get?
    end
  end
end
