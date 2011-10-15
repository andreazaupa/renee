class Renee
  class Core
    class Application
      # A module that defines useful Rack interaction methods.
      module RackInteraction

        # Creates an ad-hoc Rack application within the context of a Rack::Builder.
        # @example
        #     get { halt build { use Rack::ContentLength; run proc { |env| Rack::Response.new("Hello!").finish } } }
        #
        def build(&blk)
          run Rack::Builder.new(&blk).to_app
        end

        def build!(&blk)
          run! build(&blk)
        end

        # Runs a rack application
        # @example
        #     get { halt run proc { |env| Renee::Core::Response.new("Hello!").finish } }
        #
        def run(app = nil, &blk)
          (app || blk).call(env)
        end

        # Runs a rack application and responds immediately.
        #
        # @see #run
        # @example
        #     get { run proc { |env| Renee::Core::Response.new("Hello!").finish } }
        #
        def run!(*args)
          halt! run(*args)
        end
      end
    end
  end
end