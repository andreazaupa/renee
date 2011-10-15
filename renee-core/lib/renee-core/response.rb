class Renee
  class Core
    # The response object for a Renee request. Inherits from the `Rack#Response` object.
    class Response < Rack::Response
      # Augment body to allow strings.
      #
      # @param [String] The contents for the response.
      #
      # @example
      #  res.body = "Hello"
      #
      # @api semipublic
      def body=(value)
        value = value.body while Rack::Response === value
        @body = String === value ? [value.to_str] : value
      end

      # Alias status and body methods to allow redefinition
      alias :status_attr :status
      alias :status_attr= :status=
      alias :body_attr  :body
      alias :body_attr= :body=

      # Get or set the status of the response.
      #
      # @param [String] val The status code to return.
      #
      # @example
      #  res.status 400
      #  res.status => 400
      #
      # @api public
      def status(val=nil)
        val ? self.status_attr = val : self.status_attr
      end

      # Get or set the body of the response.
      #
      # @param [String] val The contents to return.
      #
      # @example
      #  res.body "hello"
      #  res.body => "hello"
      #
      # @api public
      def body(val=nil)
        val ? self.body_attr = val : self.body_attr
      end

      # Get or set the headers of the response.
      #
      # @param [Hash] attrs The contents to return.
      #
      # @example
      #   res.headers :foo => "bar"
      #   res.headers => { :foo => "bar" }
      #
      # @api public
      def headers(attrs={})
        attrs ? attrs.each { |k, v| self[k.to_s] = v } : self.header
      end

      # Finishs the response based on the accumulated options.
      # Calculates the size of the body content length and removes headers for 1xx status codes.
      def finish
        if status.to_i / 100 == 1
          headers.delete "Content-Length"
          headers.delete "Content-Type"
        elsif Array === body and not [204, 304].include?(status.to_i)
          headers["Content-Length"] = body.inject(0) { |l, p| l + Rack::Utils.bytesize(p) }.to_s
        end

        status, headers, result = super
        [status, headers, result]
      end
    end
  end
end