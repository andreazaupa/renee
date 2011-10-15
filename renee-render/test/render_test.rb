require File.expand_path('../test_helper', __FILE__)

describe Renee::Render do
  describe "#render" do
    after  { remove_views }

    it "should allow rendering string with engine" do
      mock_app {
        path("/a") { get { render! :erb, "<p>test</p>" } }
        path("/b") { get { render! :erb, "<p><%= foo %></p>", :locals => { :foo => "bar" } } }
        path("/c") { get { halt render(:erb, "<p><%= foo %></p>", :locals => { :foo => "bar" }) } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal "<p>test</p>", response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>", response.body
      get('/c')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>", response.body
    end # string, with engine

    it "should allow rendering template file with engine" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      mock_app {
        path("/a") { get { render! :haml, :index } }
        path("/b") { get { render! :haml, :foo, :locals => { :foo => "bar" } } }
        path("/c") { get { halt render(:haml, :foo, :locals => { :foo => "bar" }) } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal "<p>test</p>\n", response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>\n", response.body
      get('/c')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>\n", response.body
    end # template, with engine

    it "should allow rendering template file with unspecified engine" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      mock_app {
        path("/a") { get { render! "index" } }
        path("/b") { get { render! "foo.haml", :locals => { :foo => "bar" } } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal "<p>test</p>\n", response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>\n", response.body
    end # template, unspecified engine

    it "should allow rendering template file with engine and layout" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      create_view :layout, "%div.wrapper= yield", :haml
      mock_app {
        path("/a") { get { render! :haml, :index, :layout => :layout } }
        path("/b") { get { render! :foo, :layout => :layout, :locals => { :foo => "bar" } } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>test</p></div>\n}, response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>bar</p></div>\n}, response.body
    end # with engine and layout specified

    it "should allow rendering template with different layout engines" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      create_view :base, "<div class='wrapper'><%= yield %></div>", :erb
      mock_app {
        path("/a") { get { render! :haml, :index, :layout => :base, :layout_engine => :erb } }
        path("/b") { get { render! :foo, :layout => :base, :locals => { :foo => "bar" } } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>test</p>\n</div>}, response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>bar</p>\n</div>}, response.body
    end # different layout and template engines

    it "should fail properly rendering template file with invalid engine" do
      create_view :index, "%p test", :haml
      mock_app {
        get { render! :fake, :index }
      }
      assert_raises(Renee::Render::TemplateNotFound) { get('/') }
    end # template, invalid engine

    it "should fail properly rendering missing template file with engine" do
      create_view :index, "%p test", :haml
      mock_app {
        get { render! :haml, :foo }
      }
      assert_raises(Renee::Render::TemplateNotFound) { get('/') }
    end # missing template, with engine

    it "should fail properly rendering invalid data" do
      create_view :index, "%p test", :haml
      mock_app {
        get { render! :haml, /invalid regex data/ }
      }
      assert_raises(Renee::Render::RenderError) { get('/') }
    end # missing template, with engine
  end
end