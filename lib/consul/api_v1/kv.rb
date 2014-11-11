module Consul
  module APIv1
    class KV < EndpointCategory
      define_endpoint :get, ':key', params: %w[keys raw recurse separator], supports: %w[blocking consistency_modes dc token]
      define_endpoint :put, ':key', params: %w[acquire cas flags release], supports: %w[dc token]
      define_endpoint :delete, ':key', params: %w[recurse], supports: %w[dc token]

      def acquire(key, session, options = nil)
        options = Options.new(options) { |o| o.acquire = session }
        put(key, options)
      end

      def create(key, options = nil)
        options = Options.new(options) { |o| o.cas = 0 }
        put(key, options)
      end

      def delete_all(options = nil)
        prefix = nil
        options = Options.new(options) do |o|
          o.recurse = true
          prefix = o.delete(:prefix)
        end

        delete(prefix, options)
      end

      def get_all_keys(options = nil)
        prefix = nil
        options = Options.new(options) do |o|
          o.keys = true
          prefix = o.delete(:prefix)
        end

        get(prefix, options)
      end

      def get_keys(options = nil)
        prefix = nil
        options = Options.new(options) do |o|
          o.keys = true
          o.separator = '/'
          prefix = o.delete(:prefix)
        end

        get(prefix, options)
      end

      def get_value(key, options = nil)
        options = Options.new(options) { |o| o.raw = true }
        get(key, options)
      end

      def release(key, session, options = nil)
        options = Options.new(options) { |o| o.release = session }
        put(key, options)
      end
    end
  end
end
