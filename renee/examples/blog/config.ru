$: << File.expand_path("../../lib", File.dirname(__FILE__))
$: << File.dirname(__FILE__)
require 'renee'
require 'blog'
require 'json'

blog = Blog.new

run Renee {
  @blog = blog

  # find blog post and do things to it.
  var Integer do |id|
    @post = @blog.find_post(id)
    halt 404 unless @post
    path('edit') { render! 'edit' }

    get { render! 'show' }
    delete { @post.delete!; halt :ok }
    put {
      @post.title = request['title'] if request['title']
      @post.contents = request['contents'] if request['contents']
      halt :ok
    }
  end

  post {
    if request['title'] && request['contents']
      @blog.new_post(request['title'], request['contents'])
      halt :created
    else
      halt :bad_request
    end
  }

  extension('json') { get { halt @blog.posts.map{ |p| {:contents => p.contents} }.to_json } }
  no_extension      { get { render! 'index' } }
}.setup {
  views_path File.expand_path(File.dirname(__FILE__) + "/views")
}