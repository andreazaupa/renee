require File.expand_path('../test_helper', __FILE__)

describe "Blog example" do
  before  { @app = blog_app }

  it "should respond to GET /" do
    get('/')
    assert_equal 200, response.status
    assert_equal "
<p>No posts</p>
<br/>
<form action=/ method=post>
  Title
  <input name=title><br/>
  <textarea name=contents></textarea><br/>
  <input type=submit>
</form>", response.body
  end

  it "should allow a POST to /" do
    post('/', :title => 'my title', :contents => 'hey hey hey')
    assert_equal 201, response.status
    get('/')
    assert_equal 200, response.status
    assert_equal "  <p>
    Title:
    <a href='/1'>my title</a>
    <br />
    hey hey hey
  </p>


<br/>
<form action=/ method=post>
  Title
  <input name=title><br/>
  <textarea name=contents></textarea><br/>
  <input type=submit>
</form>", response.body
  end

  it "should allow a PUT to /" do
    post('/', :title => 'my title', :contents => 'hey hey hey')
    put('/1', :title => 'my real title', :contents => 'hey hey hey')
    assert_equal 200, response.status
    get('/')
    assert_equal 200, response.status
    assert_equal "  <p>
    Title:
    <a href='/1'>my real title</a>
    <br />
    hey hey hey
  </p>


<br/>
<form action=/ method=post>
  Title
  <input name=title><br/>
  <textarea name=contents></textarea><br/>
  <input type=submit>
</form>", response.body
  end

  it "should allow a DELETE to /" do
    post('/', :title => 'my title', :contents => 'hey hey hey')
    assert_equal 201, response.status
    get('/.json')
    assert_equal 200, response.status
    assert_equal "[{\"contents\":\"hey hey hey\"}]", response.body
    delete('/1')
    assert_equal 200, response.status
    get('/.json')
    assert_equal 200, response.status
    assert_equal "[]", response.body
  end

end
