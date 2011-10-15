require 'rubygems'
gem 'minitest'
require 'minitest/autorun'
gem 'rack-test'
require 'rack/test'

class ColoredIO
  ESC = "\e["
  NND = "#{ESC}0m"

  def initialize(io)
    @io = io
  end

  def print(o)
    case o
    when "."
      @io.send(:print, "#{ESC}32m#{o}#{NND}")
    when "E"
      @io.send(:print, "#{ESC}33m#{o}#{NND}")
    when "F"
      @io.send(:print, "#{ESC}31m#{o}#{NND}")
    else
      @io.send(:print, o)
    end
  end

  def puts(*o)
    super
  end
end

MiniTest::Unit.output = ColoredIO.new(MiniTest::Unit.output)

## TEST HELPERS
class MiniTest::Spec
  include Rack::Test::Methods

  # Sets up a Sinatra::Base subclass defined with the block
  # given. Used in setup or individual spec methods to establish
  # the application.
  def mock_app(&block)
    path = default_views_path
    @app = Renee::Core.new(&block).setup {
      views_path path
    }
  end

  def default_views_path
    File.dirname(__FILE__) + "/views"
  end

  def app
    Rack::Lint.new(@app)
  end

  alias :response :last_response

  # create_view :index, "test", :haml
  def create_view(name, content, engine=:erb)
    FileUtils.mkdir_p(default_views_path)
    file = File.join(default_views_path, name.to_s + ".#{engine}")
    File.open(file, 'w') { |io| io.write content }
  end

  # Removes the view folder after the test
  def remove_views
    FileUtils.rm_rf(File.dirname(__FILE__) + "/views")
  end
end
