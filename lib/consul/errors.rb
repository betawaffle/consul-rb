module Consul
  Error = Class.new(StandardError)

  SafetyViolation = Class.new(Error)

  class APIError < Error
    class << self
      def new(typhoeus_response)
        return super if self != APIError

        case code = typhoeus_response.response_code
        when 100...300
          raise ArgumentError, "HTTP #{code} is not an error!"
        when 400...500
          ClientError.new(typhoeus_response)
        when 500...600
          ServerError.new(typhoeus_response)
        else
          super
        end
      end
    end

    attr_reader :response

    def initialize(typhoeus_response)
      @response = typhoeus_response

      # TODO: Do something slightly more sophisticated here.
      if status_code
        msg = "#{status_line}: #{body.inspect}"
      else
        msg = "received #{@response.return_code} from libcurl: #{@response.return_message}"
      end

      super msg
    end

    def body
      @response.response_body
    end

    def status_code
      case code = @response.response_code
      when 0
        nil
      else
        code
      end
    end

    def status_line
      @response.response_headers.split("\r\n", 2).first
    end
  end # APIError

  class ClientError < APIError
    class << self
      def new(typhoeus_response)
        return super if self != ClientError

        case code = typhoeus_response.response_code
        when 404
          NotFoundError.new(typhoeus_response)
        else
          super
        end
      end
    end
  end

  class ServerError < APIError
  end

  class NotFoundError < ClientError
  end
end
