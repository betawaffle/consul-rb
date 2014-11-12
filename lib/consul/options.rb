module Consul
  class Options < Hash
    KNOWN_PARAMS = %w[
      acquire
      cas
      dc
      flags
      index
      keys
      name
      node
      note
      passing
      pretty
      raw
      recurse
      release
      separator
      service
      tag
      wait
      wan
    ].map(&:to_sym)

    SPECIAL_OPTIONS = %w[
      raise_error
      retries
    ].map(&:to_sym)

    attr_accessor *SPECIAL_OPTIONS

    def initialize(from = nil)
      super(&nil)
      replace(from)

      if block_given?
        yield self
        freeze
      end
    end

    def acquire=(session)
      case session
      when Session
        params[:acquire] = session.id
      when String, nil
        params[:acquire] = session
      else
        raise ArgumentError, "must be a Session or session ID, got #{session.class}"
      end
    end

    def body=(body)
      self[:body] = body
    end

    def cas=(index)
      params[:cas] = index
    end

    def consistency_mode=(mode)
      case mode
      when nil, :default, 'default'
        params.delete(:consistent) or params.delete(:stale)
      when :consistent, 'consistent'
        params.delete(:stale)
        params[:consistent] = true
      when :stale, 'stale'
        params.delete(:consistent)
        params[:stale] = true
      else
        raise ArgumentError, "#{mode.inspect} is not a valid consistency mode"
      end
    end

    def dc
      params[:dc] if params?
    end

    def dc=(dc)
      params[:dc] = dc
    end

    def flags=(flags)
      params[:flags] = flags
    end

    def freeze
      params.freeze if has_key? :params
      super
    end

    def has_param?(key, ignore_falsy = false)
      return false unless has_key? :params
      if ignore_falsy
        !!params[key]
      else
        params.has_key? key
      end
    end

    def index=(index)
      params[:index] = index
    end

    def keys=(bool)
      params[:keys] = bool
    end

    def method=(method)
      self[:method] = method
    end

    def name=(name)
      params[:name] = name
    end

    def node=(node)
      params[:node] = node
    end

    def note=(note)
      params[:note] = note
    end

    def params
      self[:params] ||= {}
    end

    def params?
      return false unless has_key? :params
      params.empty?
    end

    def passing=(bool)
      params[:passing] = bool
    end

    def pretty=(bool)
      params[:pretty] = bool
    end

    def raw=(bool)
      params[:raw] = bool
    end

    def recurse=(bool)
      params[:recurse] = bool
    end

    def release=(session)
      case session
      when Session
        params[:acquire] = session.id
      when String, nil
        params[:acquire] = session
      else
        raise ArgumentError, "must be a Session or session ID, got #{session.class}"
      end
    end

    def replace(from)
      case from
      when Options
        super
        SPECIAL_OPTIONS.each { |k| __send__ :"#{k}=", from.__send__(k) }
      when Hash
        super
      when nil
        # nothing to do
      else
        raise ArgumentError, "must be a Hash, got #{from.class}"
      end

      extract_params!
      extract_special_options!
    end

    def restrict_params!(allowed)
      return unless params?
      params.keep_if { |key| allowed.include? key }
    end

    def separator=(separator)
      params[:separator] = separator
    end

    def service=(service)
      params[:service] = service
    end

    def tag=(tag)
      params[:tag] = tag
    end

    def to_hash
      {}.replace(self)
    end

    def token=(token)
      params[:token] = token
    end

    def token?
      has_param? :token
    end

    def wait=(timeout)
      case timeout
      when String, nil
        params[:wait] = timeout
      when Integer # nanoseconds
        if timeout < 1000
          # TODO: Warn about conversion to seconds.
        end
        params[:wait] = timeout
      else
        raise ArgumentError, "must be a String or Integer, got #{timeout.class}"
      end
    end

    def wan=(bool)
      params[:wan] = bool
    end

    private

    def extract_params!
      params = self[:params] || {}
      params = params.dup if params.frozen?

      KNOWN_PARAMS.each do |param|
        if val = delete(param)
          params[param] = val
        end
      end

      self[:params] = params
    end

    def extract_special_options!
      SPECIAL_OPTIONS.each { |k| instance_variable_set :"@#{k}", delete(k) if has_key? k }
    end
  end
end
