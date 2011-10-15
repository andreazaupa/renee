# Renee

The super friendly rack-based web framework.

## Introduction

Renee is a new Rack-based library for describing web applications. Sinatra delivered a new simple way to think about building web applications. The popularity of Sinatra both as a library and as a concept shows now enduring the concept really was. Sinatra was different from Rails because the entire DSL was lightweight, easy to read and combined routing and actions into a single file. However, let's consider an example from Sinatra to see where we can improve upon this.

Consider:

```ruby
get '/blog/:id' do
  Blog.get(params[:id])
end
```

This is not too bad so far. The repetition of `:id` is a bit un-DRY, but not bad. Let's keep expanding upon this.

```ruby
get '/blog/:id' do
  Blog.get(params[:id])
end

put '/blog/:id' do
  Blog.get(params[:id]).update_attributes(params)
end
```

Now, we've retrieved blog in two places. Time to refactor. We'd normally create a before filter, with the same path.

```ruby
before '/blog/:id' do
  @blog = Blog.get(params[:id])
end

get '/blog/:id' do
  @blog
end

put '/blog/:id' do
  @blog.update_attributes(params)
end
```

Now we've repeated the same path three times. With Renee, we can describe these kind of ideas in a simple, easy-to-read way. Here is the equivalent in Renee.

```ruby
path 'blog' do
  var do |id|
    @blog = Blog.get(id)
    get { halt @blog }
    put { @blog.update(request.params); halt :ok}
  end
end
```

This web library is inspired by Sinatra, but offers an approach more inline with Rack itself, and lets you maximize code-reuse within your application.

## Installation

Setup Renee by running:

```
gem install renee
```

or by adding `Renee` to your `Gemfile`:

```ruby
# Gemfile
gem "renee", "~> 0.0.1"
```

Now you can start using Renee for your application!

## Usage

In your rackup file, give this a go!

```ruby
require 'renee'

run Renee::Core.new {
  path('test') do
    get { halt "Hey, this is a get!" }
    post { halt "and .. a post" }

    var do |id|
      halt "Getting the blog with id #{id}"
    end
  end
}
```

This rack-app will respond to GET /test with "Hey, this is a get!", POST /test with "and .. a post" and /test/:id with `"Getting the blog with id #{id}"`.

A more complete example might be sample RESTful routing definitions for a blog post resource:

```ruby
require 'renee'

run Renee::Core.new {
  path('posts') do
    @posts = Post.all
    # GET /posts
    get  { render! "index" }
    # POST /posts
    post { redirect! "/posts/index" }

    path('new') do
      # GET /posts/new
      get { render! "new" }
    end

    var :type => Integer  do |id|
      @post = Post.find(id)

      # GET /posts/5
      get { render! 'show' }
      # PUT /posts/5
      put { halt "update" }
      # DELETE /posts/5
      delete { halt "delete" }

      path('edit') do
        # GET /posts/5/edit
        get { render! "edit" }
      end
    end
  end
}
```

This implements the standard 7 REST actions in a very concise and simple way. The routes and the actions blended together utilizing the various
Renee routing methods and block syntax. The routing methods are defined below, followed by an explanation of how to respond to a route.