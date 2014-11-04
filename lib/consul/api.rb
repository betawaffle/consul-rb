require 'typhoeus'
require 'json'

module Consul
  class API
    DEFAULT_URL = 'http://127.0.0.1:8500'
    MIME_JSON   = 'application/json'.freeze

    def initialize(url_or_opts, opts = nil)
      case url_or_opts
      when String
        uri = URI(url_or_opts)
        uri.path = uri.path.chomp('/')

        opts = {} unless opts
      when Hash
        uri = URI(DEFAULT_URL)

        if opts
          opts = url_or_opts.merge(opts)
        else
          opts = url_or_opts
        end
      when nil
        uri  = URI(DEFAULT_URL)
        opts = {} unless opts
      else
        raise TypeError, "expected String or Hash, got #{url_or_opts.class}"
      end

      if host = opts[:host]
        uri.host = host
      end

      if port = opts[:port]
        uri.port = port.to_i
      end

      @uri   = uri
      @token = opts[:token]
      @wait  = opts[:wait]

      case mode = opts[:consistency_mode] || opts[:mode]
      when nil, :default, 'default'
        @mode = nil
      when :consistent, 'consistent'
        @mode = :consistent
      when :stale, 'stale'
        @mode = :stale
      else
        raise TypeError, "expected :consistent or :stale, got #{mode}"
      end
    end

    def [](key)
      KV.new(self, key)
    end

    def create_session(*args)
      Session.create(self, *args)
    end

    def new_request(method, path, params = nil, opts = nil)
      options = { method: method }
      options.merge!(opts) if opts

      if params
        options[:params] = default_params(method, path, opts).merge(params)
      else
        options[:params] = default_params(method, path, opts)
      end

      url = @uri.to_s + (path[0] == '/' ? path : "/#{path}")
      req = ::Typhoeus::Request.new(url, options)
      req.on_complete do |res|
        next res unless res.headers['Content-Type'] == MIME_JSON
        JSON.parse(res.body) rescue res
      end

      req
    end

    def to_s
      %[#<#{self.class} #{@uri}>]
    end

    private

    def default_params(method, path, opts)
      token = @token
      mode  = @mode
      wait  = @wait

      if opts
        index = opts[:index]
        wait  = opts.fetch(:wait, wait)
        token = opts.fetch(:token, token)
        mode  = opts.fetch(:consistency_mode) { opts.fetch(:mode, mode) }
      end

      # TODO: Some of these params only apply to some endpoints.
      #       Use method and path to decide which params to use.
      params = {}

      if index
        params[:index] = index
        params[:wait]  = wait if wait
      end

      params[:token] = token if token
      params[mode] = true if mode
      params
    end
  end
end
