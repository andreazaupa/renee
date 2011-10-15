class Renee
  class Core
    class Application
      # Collection of useful methods for routing within a {Renee::Core} app.
      module Routing
        # Match a path to respond to.
        #
        # @param [String] p
        #   path to match.
        # @param [Proc] blk
        #   block to yield
        #
        # @example
        #   path('/')    { ... } #=> '/'
        #   path('test') { ... } #=> '/test'
        #
        #   path 'foo' do
        #     path('bar') { ... } #=> '/foo/bar'
        #   end
        #
        # @api public
        def path(p, &blk)
          p = p[1, p.size] if p[0] == ?/
          part(/^\/#{Regexp.quote(p)}(\/?$)?/, &blk)
        end

        # Like #path, but requires the entire path to be consumed.
        # @see #path
        def whole_path(p, &blk)
          path(p) { complete(&blk) }
        end

        # Like #path, but doesn't automatically match trailing-slashes.
        # @see #path
        def exact_path(p, &blk)
          p = p[1, part.size] if p[0] == ?/
          part(/^\/#{Regexp.quote(p)}/, &blk)
        end

        # Like #path, doesn't look for leading slashes.
        def part(p)
          p = /\/?#{Regexp.quote(p)}/ if p.is_a?(String)
          if match = env['PATH_INFO'][p]
            with_path_part(match) { yield }
          end
        end

        # Match parts off the path as variables.
        #
        # @example
        #   path '/' do
        #     variable { |id| halt [200, {}, id }
        #   end
        #   GET /hey  #=> [200, {}, 'hey']
        #
        #   path '/test' do
        #     variable { |foo, bar| halt [200, {}, "#{foo}-#{bar}"] }
        #   end
        #   GET /test/hey/there  #=> [200, {}, 'hey-there']
        #
        # @api public
        def variable(*args, &blk)
          args << {} unless args.last.is_a?(Hash)
          args.last[:prepend] = '/'
          partial_variable(*args, &blk)
        end
        alias_method :var, :variable

        # Match parts off the path as variables without a leading slash.
        # @see #variable
        # @api public
        def partial_variable(*args, &blk)
          opts = args.last.is_a?(Hash) ? args.pop : nil
          type = args.first || opts && opts[:type]
          prepend = opts && opts[:prepend] || ''
          if type == Integer
            complex_variable(/#{Regexp.quote(prepend)}(\d+)/, proc{|v| Integer(v)}, &blk)
          else case type
            when nil
              complex_variable(/#{Regexp.quote(prepend)}([^\/]+)/, &blk)
            when Regexp
              complex_variable(/#{Regexp.quote(prepend)}(#{type.to_s})/, &blk)
            else
              raise "Unexpected variable type #{type.inspect}"
            end
          end
        end
        alias_method :part_var, :partial_variable

        # Match an extension.
        #
        # @example
        #   extension('html') { |path| halt [200, {}, path] }
        #
        # @api public
        def extension(ext)
          if detected_extension && match = detected_extension[ext]
            if match == detected_extension
              (ext_match = env['PATH_INFO'][/\/?\.#{match}/]) ?
                with_path_part(ext_match) { yield } : yield
            end
          end
        end
        alias_method :ext, :extension

        # Match no extension.
        #
        # @example
        #   no_extension { |path| halt [200, {}, path] }
        #
        # @api public
        def no_extension
          yield if detected_extension.nil?
        end

        # Match any remaining path.
        #
        # @example
        #   remainder { |path| halt [200, {}, path] }
        #
        # @api public
        def remainder
          with_path_part(env['PATH_INFO']) { |var| yield var }
        end
        alias_method :catchall, :remainder

        # Respond to a GET request and yield the block.
        #
        # @example
        #   get { halt [200, {}, "hello world"] }
        #
        # @api public
        def get(path = nil)
          request_method('GET', path) { yield }
        end

        # Respond to a POST request and yield the block.
        #
        # @example
        #   post { halt [200, {}, "hello world"] }
        #
        # @api public
        def post(path = nil)
          request_method('POST', path) { yield }
        end

        # Respond to a PUT request and yield the block.
        #
        # @example
        #   put { halt [200, {}, "hello world"] }
        #
        # @api public
        def put(path = nil)
          request_method('PUT', path) { yield }
        end

        # Respond to a DELETE request and yield the block.
        #
        # @example
        #   delete { halt [200, {}, "hello world"] }
        #
        # @api public
        def delete(path = nil)
          request_method('DELETE', path) { yield }
        end

        # Match only when the path has been completely consumed.
        #
        # @example
        #   delete { halt [200, {}, "hello world"] }
        #
        # @api public
        def complete
          with_path_part(env['PATH_INFO']) { yield } if env['PATH_INFO'] == '' || is_index_request
        end

        # Match variables within the query string.
        #
        # @param [Array, Hash] q
        #   Either an array or hash of things to match query string variables. If given
        #   an array, if you pass the values for each key as parameters to the block given.
        #   If given a hash, then every value must be able to #=== match each value in the query
        #   parameters for each key in the hash.
        #
        # @example
        #   query(:key => 'value') { halt [200, {}, "hello world"] }
        #
        # @example
        #   query(:key) { |val| halt [200, {}, "key is #{val}"] }
        #
        # @api public
        def query(q, &blk)
          case q
          when Hash  then q.any? {|k,v| !(v === request[k.to_s]) } ? return : yield
          when Array then yield *q.map{|qk| request[qk.to_s] or return }
          else            query([q], &blk)
          end
        end

        # Yield block if the query string matches.
        #
        # @param [String] qs
        #   The query string to match.
        #
        # @example
        #   path 'test' do
        #     query_string 'foo=bar' do
        #       halt [200, {}, 'matched']
        #     end
        #   end
        #   GET /test?foo=bar #=> 'matched'
        #
        # @api public
        def query_string(qs)
          yield if qs === env['QUERY_STRING']
        end

        private
        def complex_variable(matcher = nil, transformer = nil, &blk)
          warn "variable currently isn't taking any parameters" unless blk.arity > 0
          if var_value = /^#{(matcher ? matcher.to_s : '\/([^\/]+)') * blk.arity}/.match(env['PATH_INFO'])
            vars = var_value.to_a
            with_path_part(vars.shift) { blk.call *vars.map{|v| transformer ? transformer[v[0, v.size]] : v[0, v.size]} }
          end
        end

        def with_path_part(part)
          old_path_info = env['PATH_INFO']
          old_script_name = env['SCRIPT_NAME']
          old_path_info[part.size, old_path_info.size - part.size]
          script_part, remaining_part = old_path_info[0, part.size], old_path_info[part.size, old_path_info.size]
          env['SCRIPT_NAME'] += script_part
          env['PATH_INFO'] = remaining_part
          yield script_part
          env['PATH_INFO'] = old_path_info
          env['SCRIPT_NAME'] = old_script_name
        end

        def request_method(method, path = nil)
          path ? whole_path(path) { yield } : complete { yield } if env['REQUEST_METHOD'] == method
        end
      end
    end
  end
end
