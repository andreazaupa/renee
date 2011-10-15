require 'uri'

class Renee
  class Core
    # URL generator for creating paths and URLs within your application.
    module URLGeneration

      # Registers new paths for generation.
      # @param [Symbol] name The name of the path
      # @param [String] pattern The pattern used for generation.
      # @param [Hash, nil] defaults Any default values used for generation.
      #
      # @example
      #     renee.register(:path, "/my/:var/path")
      #     renee.path(:path, 123) # => "/my/123/path"
      #     renee.path(:path, :var => 'hey you') # => "/my/hey%20you/path"
      def register(name, pattern, defaults = nil)
        url_generators[name] = Generator.new("#{@generation_prefix}#{pattern}", defaults_for_generation(defaults))
      end

      # Allows the creation of generation contexts.
      # @param [String] prefix The prefix to add to subsequent calls to #register.
      # @param [Hash, nil] defaults The defaults to add to subsequent calls to #register.
      # @see #register
      #
      # @example
      #     renee.prefix("/prefix") {
      #       renee.register(:prefix_path, "/path") # would register /prefix/path
      #     }
      def prefix(prefix, defaults = nil, &blk)
        generator = self
        subgenerator = Class.new {
          include URLGeneration
          define_method(:url_generators) { generator.send(:url_generators) }
        }.new
        subgenerator.instance_variable_set(:@generation_prefix, "#{@generation_prefix}#{prefix}")
        subgenerator.instance_variable_set(:@generation_defaults, defaults_for_generation(defaults))
        if block_given?
          old_prefix, old_defaults = @generation_prefix, @generation_defaults
          @generation_prefix, @generation_defaults = "#{@generation_prefix}#{prefix}", defaults_for_generation(defaults)
          subgenerator.instance_eval(&blk)
          @generation_prefix, @generation_defaults = old_prefix, old_defaults
        end
        subgenerator
      end

      # Generates a path for a given name.
      # @param [Symbol] name The name of the path
      # @param [Object] args The values used to generate the path. Can be named with using :name => "value" or supplied
      #                   in the order for which the variables were decalared in #register.
      #
      # @see #register
      def path(name, *args)
        generator = url_generators[name]
        generator ? generator.path(*args) : raise("Generator for #{name} doesn't exist")
      end

      # Generates a url for a given name.
      # @param (see #path)
      # @see #path
      def url(name, *args)
        generator = url_generators[name]
        generator ? generator.url(*args) : raise("Generator for #{name} doesn't exist")
      end

      private
      def url_generators
        @url_generators ||= {}
      end

      def defaults_for_generation(defaults)
        @generation_defaults && defaults ? @generation_defaults.merge(defaults) : (defaults || @generation_defaults)
      end

      # Manages generating paths and urls for a given name.
      # @private
      class Generator
        attr_reader :defaults

        def initialize(template, defaults = nil)
          @defaults = defaults
          parsed_template = URI.parse(template)
          @host = parsed_template.host
          @template = parsed_template.path
          @scheme = parsed_template.scheme
          port = parsed_template.port
          if !port.nil? and (@scheme.nil? or @scheme == "http" && port != '80' or @scheme == "https" && port != '443')
            @port_part = ":#{port}"
          end
        end

        def path(*args)
          opts = args.last.is_a?(Hash) ? args.pop : nil
          opts = opts ? defaults.merge(opts) : defaults.dup if defaults
          path = @template.gsub(/:([a-zA-Z0-9_]+)/) { |name|
            name = name[1, name.size - 1].to_sym
            (opts && opts.delete(name)) || (defaults && defaults[name]) || args.shift || raise("variable #{name.inspect} not found")
          }
          URI.encode(opts.nil? || opts.empty? ? path : "#{path}?#{Rack::Utils.build_query(opts)}")
        end

        def url(*args)
          raise "This URL cannot be generated as no host has been defined." if @host.nil?
          "#{@scheme}://#{@host}#{@port_part}#{path(*args)}"
        end
      end
    end
  end
end