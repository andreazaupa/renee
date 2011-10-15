require File.expand_path('../test_helper', __FILE__)

describe Renee::Core::Application::Routing do

  def renee_for(path, options = {}, &block)
    Renee::Core.new(&block).call(Rack::MockRequest.env_for(path, options))
  end

  describe "with paths" do
    it "generates a basic route" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path('/')   { get { halt [200,type,['foo']] } }
        path('bar') { put { halt [200,type,['bar']] } }

        path '/foo' do
          delete { halt [200,type,['hi']] }

          path '/bar/har' do
            get  { halt [200,type,['foobar']] }
            post { halt [200,type,['posted']] }
          end

        end
      end
      get '/'
      assert_equal 200,   response.status
      assert_equal 'foo', response.body
      put '/bar'
      assert_equal 200,   response.status
      assert_equal 'bar', response.body
      delete '/foo'
      assert_equal 200,   response.status
      assert_equal 'hi', response.body
      get '/foo/bar/har'
      assert_equal 200,   response.status
      assert_equal 'foobar', response.body
      post '/foo/bar/har'
      assert_equal 200,   response.status
      assert_equal 'posted', response.body
    end

    it "accepts a query string" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path('test') { get { halt [200, type, [env['QUERY_STRING']]] } }

        path 'foo' do
          query_string 'bar' do
            get { halt [200,type,['bar']] }
          end

          query_string 'foo=bar' do
            post { halt [200,type,['foo']] }
          end
        end
      end

      get '/test?bar'
      assert_equal 200,   response.status
      assert_equal 'bar', response.body
      get '/foo?bar'
      assert_equal 200,   response.status
      assert_equal 'bar', response.body
      post '/foo?foo=bar'
      assert_equal 200,   response.status
      assert_equal 'foo', response.body
    end

    it "accepts a set of query params (as hash)" do
      mock_app do
        path 'test' do
          query :foo => "bar" do
            halt 200
          end
        end
      end

      get '/test?foo=bar'
      assert_equal 200, response.status
      get '/test?foo=bar2'
      assert_equal 404, response.status
    end

    it "accepts a set of query params (as an array)" do
      mock_app do
        path 'test' do
          query :foo do |var|
            case var
            when 'bar'  then halt 200
            when 'bar2' then halt 500
            end
          end
        end
      end
      get '/test?foo=bar'
      assert_equal 200, response.status
      get '/test?foo=bar2'
      assert_equal 500, response.status
    end

    describe "with trailing slashes" do
      it "should ignore trailing slashes normally" do
        type = { 'Content-Type' => 'text/plain' }
        mock_app do
          path('test') { get { halt [200,type,['test']] } }
        end

        get '/test/'
        assert_equal 200,    response.status
        assert_equal 'test', response.body
        get '/test'
        assert_equal 200,    response.status
        assert_equal 'test', response.body
      end

      it "should not ignore trailing slashes if told not to" do
        type = { 'Content-Type' => 'text/plain' }
        mock_app do
          exact_path('test') { get { halt [200,type,['test']] } }
        end
        get '/test/'
        assert_equal 404,    response.status
        get '/test'
        assert_equal 200,    response.status
        assert_equal 'test', response.body
      end
    end
  end

  describe "with variables" do

    it "generates for path" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path 'test' do
          variable do  |id|
            get { halt [200,type,[id]] }
          end
        end

        path 'two' do
          variable do |foo, bar|
            get { halt [200, type,["#{foo}-#{bar}"]] }
          end
        end

        path 'multi' do
          variable do |foo, bar, lol|
            post { halt [200, type,["#{foo}-#{bar}-#{lol}"]] }
          end
        end
      end

      get '/test/hello'
      assert_equal 200,     response.status
      assert_equal 'hello', response.body
      get '/two/1/2'
      assert_equal 200,     response.status
      assert_equal '1-2',   response.body
      post '/multi/1/2/3'
      assert_equal 200,     response.status
      assert_equal '1-2-3', response.body
    end

    it "generates nested paths" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path 'test' do
          var do  |id|
            path 'moar' do
              post { halt [200, type, [id]] }
            end

            path 'more' do
              var do |foo, bar|
                get { halt [200, type, ["#{foo}-#{bar}"]] }

                path 'woo' do
                  get { halt [200, type, ["#{foo}-#{bar}-woo"]] }
                end
              end
            end
          end
        end
      end

      post '/test/world/moar'
      assert_equal 200,       response.status
      assert_equal 'world',   response.body
      get '/test/world/more/1/2'
      assert_equal 200,       response.status
      assert_equal '1-2',     response.body
      get '/test/world/more/1/2/woo'
      assert_equal 200,       response.status
      assert_equal '1-2-woo', response.body
    end

    it "accepts an typcasts integers" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path 'add' do
          variable :type => Integer do |a, b|
            halt [200, type, ["#{a + b}"]]
          end
        end
      end

      get '/add/3/4'
      assert_equal 200, response.status
      assert_equal '7', response.body
    end

    it "accepts a regexp" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path 'add' do
          variable /foo|bar/ do |a, b|
            halt [200, type, ["#{a + b}"]]
          end
        end
      end

      get '/add/bar/foo'
      assert_equal 200,      response.status
      assert_equal 'barfoo', response.body
    end
  end

  describe "with remainder" do

    it "matches the rest of the routes" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path 'test' do
          get { halt [200,type,['test']] }

          remainder do |rest|
            post { halt [200, type, ["test-#{rest}"]] }
          end
        end

        remainder do |rest|
          halt [200, type, [rest]]
        end
      end

      get '/a/b/c'
      assert_equal 200,      response.status
      assert_equal '/a/b/c', response.body
      post '/test/world/moar'
      assert_equal 200,      response.status
      assert_equal 'test-/world/moar', response.body
    end
  end

  describe "with extensions" do
    it "should match an extension" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path '/test' do
          extension 'html' do
            halt [200, type, ['test html']]
          end
          extension 'json' do
            halt [200, type, ['test json']]
          end

          no_extension do
            halt [200, type, ['test nope']]
          end
        end
        
        extension 'html' do
          halt [200, type, ['test html']]
        end
      end
      get '/test.html'
      assert_equal 200,    response.status
      assert_equal 'test html', response.body
      get '/test.json'
      assert_equal 200,    response.status
      assert_equal 'test json', response.body
      get '/test.xml'
      assert_equal 404,    response.status
    end

    it "should match an extension when there is a non-specific variable before" do
      mock_app do
        var do |id|
          extension 'html' do
            halt "html #{id}"
          end
          extension 'xml' do
            halt "xml #{id}"
          end
          no_extension do
            halt "none #{id}"
          end
        end
      end
      get '/var.html'
      assert_equal 200,        response.status
      assert_equal 'html var', response.body
      get '/var.xml'
      assert_equal 200,        response.status
      assert_equal 'xml var',  response.body
      get '/var'
      assert_equal 200,        response.status
      assert_equal 'none var',  response.body
    end
  end

  describe "with part and part_var" do
    it "should match a part" do
      mock_app do
        part '/test' do
          part 'more' do
            halt :ok
          end
        end
      end
      get '/testmore'
      assert_equal 200,    response.status
    end

    it "should match a part_var" do
      mock_app do
        part '/test' do
          part 'more' do
            part_var do |var|
              path 'test' do
                halt var
              end
            end
          end
        end
      end
      get '/testmorethisvar/test'
      assert_equal 'thisvar',    response.body
    end

    it "should match a part_var with Integer" do
      mock_app do
        part '/test' do
          part 'more' do
            part_var Integer do |var|
              path 'test' do
                halt var.to_s
              end
            end
          end
        end
      end
      get '/testmore123/test'
      assert_equal '123',    response.body
      get '/testmore123a/test'
      assert_equal 404,    response.status
    end
  end

  describe "multiple Renee's" do
    it "should pass between them normally" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path 'test' do
          halt run Renee::Core.new {
            path 'time' do
              halt halt [200,type,['test']]
            end
          }
        end
      end
      get '/test/time'
      assert_equal 200,    response.status
      assert_equal 'test', response.body
    end

    it "should support run! passing between" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path 'test' do
          run! Renee::Core.new {
            path 'time' do
              halt halt [200,type,['test']]
            end
          }
        end
      end
      get '/test/time'
      assert_equal 200,    response.status
      assert_equal 'test', response.body
    end
  end

  describe "#build" do
    it "should allow building in-place rack apps" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        path('test') do
          halt build {
            run proc {|env| [200, type, ['someone built me!']] }
          }
        end
      end

      get '/test'
      assert_equal 200,                 response.status
      assert_equal 'someone built me!', response.body
    end
  end

  describe "#part and #part_var" do
    it "should match parts and partial vars" do
      mock_app do
        part('test') {
          part_var(Integer) { |id|
            part('more') {
              halt "the id is #{id}"
            }
          }
        }
      end
      get '/test123more'
      assert_equal 200,                 response.status
      assert_equal 'the id is 123',     response.body
    end
  end

  describe "request methods" do
    it "should allow request method routing when you're matching on /" do
      type = { 'Content-Type' => 'text/plain' }
      mock_app do
        get { halt [200, type, ["hiya"]] }
      end

      get '/'
      assert_equal 200,    response.status
      assert_equal 'hiya', response.body
    end

    it "should allow optional paths in the request method" do
      blk = proc { get('/path') { halt [200, {}, "hiya"] } }
      assert_equal [200, {}, "hiya"], renee_for('/path', &blk)
    end
  end
end
