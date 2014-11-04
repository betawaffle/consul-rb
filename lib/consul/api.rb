require 'consul/api_v1'

module Consul
  class API
    attr_reader *APIv1::CATEGORIES.keys

    def initialize(*args)
      APIv1::CATEGORIES.each_pair do |name, klass|
        instance_variable_set :"@#{name}", klass.new(*args)
      end
    end
  end
end
