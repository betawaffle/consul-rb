require 'consul/api_v1'

module Consul
  DEFAULT_BASE_URL = ENV.fetch('CONSUL_URL', 'http://127.0.0.1:8500').freeze
  MIME_JSON = 'application/json'.freeze

  class API
    attr_reader *APIv1::CATEGORIES.keys

    def initialize(*args)
      APIv1::CATEGORIES.each_pair do |name, klass|
        instance_variable_set :"@#{name}", klass.new(*args)
      end
    end
  end
end
