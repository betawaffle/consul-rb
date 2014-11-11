module Consul
  class Response < ::Typhoeus::Response
    def content_type
      headers['Content-Type']
    end

    def index
      headers['X-Consul-Index']
    end

    def json?
      content_type == MIME_JSON
    end

    def json_value
      raise 'response is not JSON' unless json?

      case body
      when 'true'
        true
      when 'false'
        false
      when 'null'
        nil
      else
        JSON.parse(body)
      end
    end

    def known_leader?
      headers['X-Consul-KnownLeader']
    end

    def last_contact
      headers['X-Consul-LastContact']
    end

    def text?
      content_type == MIME_TEXT
    end
  end
end
