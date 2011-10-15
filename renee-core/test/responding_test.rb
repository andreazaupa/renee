require File.expand_path('../test_helper', __FILE__)

describe Renee::Core::Application::Responding do
  describe "#interpret_response" do
    it "should render from a number" do
      mock_app do
        path('/') { halt 200 }
      end
      get '/'
      assert_equal 200,               response.status
      assert_equal 'Status code 200', response.body
    end

    it "should render from a symbol" do
      mock_app do
        path('/') { halt :not_found }
      end
      get '/'
      assert_equal 404,               response.status
      assert_equal 'Status code 404', response.body
    end

    it "should render from a string" do
      mock_app do
        path('/') { halt "hello!" }
      end
      get '/'
      assert_equal 200,      response.status
      assert_equal 'hello!', response.body
    end

    it "should render from an array" do
      mock_app do
        path('/') { halt 500, "hello!" }
      end
      get '/'
      assert_equal 500,      response.status
      assert_equal 'hello!', response.body
    end

    it "should render from an array with a symbol" do
      mock_app do
        path('/') { halt :payment_required, "hello!" }
      end
      get '/'
      assert_equal 403,      response.status
      assert_equal 'hello!', response.body
    end

    it "should render a rack-sized array as a rack response" do
      mock_app do
        path('/') { halt [200, {'Content-Type' => 'text/plain'}, []] }
      end
      get '/'
      assert_equal 200, response.status
    end
  end

  describe "#respond" do
    it "should allow respond! with response init arguments" do
      mock_app do
        get do
          respond!("hello!", 403, "foo" => "bar")
        end
      end
      get "/"
      assert_equal 403,   response.status
      assert_equal "bar",   response.headers["foo"]
      assert_equal "hello!", response.body
    end # respond!

    it "should allow respond!" do
      mock_app do
        get do
          respond! { status 403; headers :foo => "bar"; body "hello!" }
        end
      end
      get "/"
      assert_equal 403,   response.status
      assert_equal "bar",   response.headers["foo"]
      assert_equal "hello!", response.body
    end # respond!

    it "should allow respond" do
      mock_app do
        get do
          halt(respond { status 403; headers :foo => "bar"; body "hello!" })
        end
      end
      get "/"
      assert_equal 403,   response.status
      assert_equal "bar",   response.headers["foo"]
      assert_equal "hello!", response.body
    end # respond
  end

  describe "#redirect" do
    it "should allow redirects" do
      mock_app do
        get { halt redirect('/hello') }
      end

      get '/'
      assert_equal 302,      response.status
      assert_equal "/hello", response.headers['Location']
    end

    it "should accept custom status codes" do
      mock_app do
        get { halt redirect('/hello', 303) }
      end

      get '/'
      assert_equal 303,      response.status
      assert_equal "/hello", response.headers['Location']
    end

    it "should allow redirect!" do
      mock_app do
        get { redirect!('/hello') }
      end

      get '/'
      assert_equal 302,      response.status
      assert_equal "/hello", response.headers['Location']
    end
  end
end
