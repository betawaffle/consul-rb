require 'consul/api_v1'

module Consul
  DEFAULT_BASE_URL = ENV.fetch('CONSUL_URL', 'http://127.0.0.1:8500').freeze

  MIME_JSON = 'application/json'.freeze
  MIME_TEXT = %r[^text/plain].freeze

  class API
    attr_reader *APIv1::CATEGORIES.keys

    def initialize(base_url = DEFAULT_BASE_URL, options = {})
      @base_url = base_url.to_s.chomp('/')

      APIv1::CATEGORIES.each_pair do |name, klass|
        instance_variable_set :"@#{name}", klass.new(base_url, options)
      end
    end

    def [](key)
      KV.new(self, key)
    end

    def create_kv(key, options = nil)
      KV.create(self, key, options)
    end

    def create_session(options = nil)
      Session.create(self, options)
    end

    def fire_event(name, options = nil)
      Event.fire(self, name, options)
    end

    def inspect
      %[#<#{self.class} #{@base_url}>]
    end
  end
end
