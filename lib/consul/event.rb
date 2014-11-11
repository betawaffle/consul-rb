module Consul
  class Event
    JSON_MAPPING = {
      :id             => 'ID',
      :name           => 'Name',
      :node_filter    => 'NodeFilter',
      :service_filter => 'ServiceFilter',
      :tag_filter     => 'TagFilter',
      :version        => 'Version',
      :lamport_time   => 'LTime'
    }

    class << self
      def fire(api, name, options = nil)
        req = api.event.fire(name, options)
        req.on_success { |res| new api, res.handled_response }
        req.run.handled_response
      end

      def list(api, options = nil)
        req = api.event.list(options)
        req.on_success do |res|
          case arr = res.handled_response
          when Array
            arr.map { |info| new api, info }
          end
        end

        req.run.handled_response
      end
    end

    attr_reader *JSON_MAPPING.keys

    def initialize(api, info)
      @api = api

      JSON_MAPPING.each_pair do |var, field|
        instance_variable_set(:"@#{var}", info[field].freeze)
      end

      freeze
    end
  end
end
