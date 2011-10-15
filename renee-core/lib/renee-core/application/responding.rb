class Renee
  class Core
    class Application
      # Collection of useful methods for responding within a {Renee::Core} app.
      module Responding

        # Codes used by Symbol lookup in interpret_response.
        # @example
        #   halt! :unauthorized # would return a 401.
        #
        HTTP_CODES = {
          :ok => 200,
          :created => 201,
          :accepted => 202,
          :no_content => 204,
          :no_content => 204,
          :bad_request => 400,
          :unauthorized => 401,
          :payment_required => 403,
          :not_found => 404,
          :method_not_found => 405,
          :not_acceptable => 406,
          :gone => 410,
          :error => 500,
          :not_implemented => 501}.freeze

        # Halts current processing to the top-level calling Renee application and uses that as a response. This method requies that
        # the PATH_INFO be completely consumed.
        # @param [Object...] response The response to use.
        # @see #interpret_response
        def halt(*response)
          raise "PATH_INFO hasn't been entirely consumed, you still have #{env['PATH_INFO'].inspect} left. Try putting a #remainder block around it. " if env['PATH_INFO'] != ''
          halt! *response
        end

        # Halts current processing to the top-level calling Renee application and uses that as a response. Unlike #halt, this does
        # not require the path to be consumed.
        # @param [Object...] response The response to use.
        # @see #interpret_response
        def halt!(*response)
          throw :halt, interpret_response(response.size == 1 ? response.first : response)
        end

        ##
        # Creates a response by allowing the response header, body and status to be passed into the block.
        #
        # @param [Array] body The contents to return.
        # @param [Integer] status The status code to return.
        # @param [Hash] header The headers to return.
        # @param [Proc] &blk The response options to specify
        #
        # @example
        #  respond { status 200; body "Yay!" }
        #  respond("Hello", 200, "foo" => "bar")
        #
        def respond(body=[], status=200, header={}, &blk)
          Renee::Core::Response.new(body, status, header).tap { |r| r.instance_eval(&blk) if block_given? }.finish
        end

        ##
        # Creates a response by allowing the response header, body and status to be passed into the block.
        #
        # @example
        #  respond! { status 200; body "Yay!" }
        #
        # @param  (see #respond)
        # @see #respond
        def respond!(*args, &blk)
          halt respond(*args, &blk)
        end

        # Interprets responses returns by #halt.
        #
        # * If it is a Symbol, it will be looked up in {HTTP_CODES}.
        # * If it is a Symbol, it will use Rack::Response to return the value.
        # * If it is a Symbol, it will either be used as a Rack response or as a body and status code.
        # * If it is an Integer, it will use Rack::Response to return the status code.
        # * Otherwise, #to_s will be called on it and it will be treated as a Symbol.
        #
        # @param [Object] response This can be either a Symbol, String, Array or any Object.
        #
        def interpret_response(response)
          case response
          when Array   then
            case response.size
            when 3 then response
            when 2 then Renee::Core::Response.new(response[1], HTTP_CODES[response[0]] || response[0]).finish
            else raise "I don't know how to render #{response.inspect}"
            end
          when String  then Renee::Core::Response.new(response).finish
          when Integer then Renee::Core::Response.new("Status code #{response}", response).finish
          when Symbol  then interpret_response(HTTP_CODES[response] || response.to_s)
          else              interpret_response(response.to_s)
          end
        end

        # Returns a rack-based response for redirection.
        # @param [String] path The URL to redirect to.
        # @param [Integer] code The HTTP code to use.
        # @example
        #     r = Renee::Core.new { get { halt redirect '/index' } }
        #     r.call(Rack::MockResponse("/")) # => [302, {"Location" => "/index"}, []]
        def redirect(path, code = 302)
          response = ::Rack::Response.new
          response.redirect(path, code)
          response.finish
        end

        # Halts with a rack-based response for redirection.
        # @see #redirect
        # @param [String] path The URL to redirect to.
        # @param [Integer] code The HTTP code to use.
        # @example
        #     r = Renee::Core.new { get { redirect! '/index' } }
        #     r.call(Rack::MockResponse("/")) # => [302, {"Location" => "/index"}, []]
        def redirect!(path, code = 302)
          halt redirect(path, code)
        end
      end
    end
  end
end
