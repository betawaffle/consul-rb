module Consul
  class Request < ::Typhoeus::Request
    attr_reader :handled_response

    def initialize(base_url, options)
      super base_url, options.to_hash

      on_complete do |res|
        case res.content_type
        when MIME_JSON
          res.json_value
        when MIME_TEXT
          res.body
        else
          res
        end
      end

      unless options.raise_error == false
        on_failure { |res| raise APIError.new(res) }
      end
    end

    def finish(response, bypass_memoization = nil)
      super Response.new(response), bypass_memoization
    end
  end
end
