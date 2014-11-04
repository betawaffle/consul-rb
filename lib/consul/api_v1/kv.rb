module Consul
  module APIv1
    class KV < Category
      define_endpoint :get, ':key', params: %w[keys raw recurse separator], supports: %w[blocking consistency_modes dc token]
      define_endpoint :put, ':key', params: %w[acquire cas flags release], supports: %w[dc token]
      define_endpoint :delete, ':key', params: %w[recurse], supports: %w[dc token]

      def acquire(key, session, options = {})
        options[:acquire] = session

        put(key, options)
      end

      def create(key, options = {})
        options[:cas] = 0

        put(key, options)
      end

      def delete_all(options = {})
        options[:recurse] = true
        prefix = options.delete(:prefix)

        delete(prefix, options)
      end

      def get_all_keys(options = {})
        options[:keys] = true
        prefix = options.delete(:prefix)

        get(prefix, options)
      end

      def get_keys(options = {})
        options[:keys] = true
        options[:separator] = '/'
        prefix = options.delete(:prefix)

        get(prefix, options)
      end

      def get_value(key, options = {})
        options[:raw] = true

        get(key, options)
      end

      def release(key, session, options = {})
        options[:release] = session

        put(key, options)
      end
    end

    CATEGORIES[:kv] = KV
  end
end
