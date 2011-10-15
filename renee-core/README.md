# Renee Core

## Routing

Routing in `Renee` is different from any web framework you are likely to have used in the past. The syntax is most familiar to Sinatra but allows
for far more flexibility and freedom in the way that routes and actions are defined. In a Renee, routes are defined using the `path`, `var`, `query_string`, `extension`, `remainder` and request methods.

**Request Methods**

The bread and butter of Renee are the request verbs reminiscent of Sinatra:

```ruby
run Renee::Core.new {
  get    { halt "a get!"  }
  post   { halt "a post!" }
  put    { halt "a put!"  }
  delete { halt "a delete!" }
}
```

These will declare the response to "/" for each of the common request types. Notice the use of the request method to
specify the http verb and the use of `halt` inside the block to send back the body of the response.

**Path**

Path is how Renee describes the basic uri path for a route:

```ruby
run Renee::Core.new {
  path('blog') { ... }
}
```

All declarations inside that block will start with `/blog`. Paths can also be nested within one another:

```ruby
run Renee::Core.new {
  path('blog') {
    path('foo') { get { halt "path is /blog/foo" } }
  }
}
```

You can also use `exact_path` for more precise path matching and/or `part` which doesn't look for leading slashes.

**Query String**

In addition to defining paths, you may find yourself wanting to describe the state of the query string for a request within the path:

```ruby
path 'foo' do
  query_string 'bar' do
    get { halt 'BAR!' }
  end

  query_string 'baz' do
    get { halt 'BAZ!' }
  end
end
```

This will respond to `/foo?bar` with "BAR!" and `/foo?baz` with "BAZ!". You can also specify query_string in a variety of other ways:

```ruby
# Check key and value of query param
query_string 'foo=bar' do
  post { halt [200,{},'foo'] }
end

# Declare query params as a hash
query :foo => "bar" do
  halt 200
end

# Switch based on a query parameter
query :foo do |var|
  case var
  when 'bar' then halt 200
  when 'bar2' then halt 500
  end
end
```

**Variables**

In Renee, you specify parameters for your request as explicit variables. Variables are declared like this:

```ruby
path('blog') {
  var { |id| get { halt "path is /blog/#{id}" } }
}
```

You can access the variables (passed into the request) using the local variables yielded to the block. Variables are a powerful
way to express expected parameters for a given set of requests. You can specify variables that match a regex:

```ruby
path('blog') {
  var(/\d+/) { |id| get { halt "path is /blog/#{id}" } }
}
```

and even explicitly cast your variable types:

```ruby
path('blog') {
  var :type => Integer do |id|
    get { halt "path is /blog/#{id} and id is an integer" }
  end
end
```

**Extensions**

You can also use `extension` as a way to define formats:

```ruby
path '/test' do
  extension 'html' do
    halt 'html'
  end
  extension 'json' do
    halt 'json'
  end
end
```

This will have `test.html` respond with 'html' and `test.json` respond with 'json'.

**Remainder**

In the event that no route has been matched, the `remainder` keyword makes defining the else case rather easy:

```ruby
path 'foo' do
  path 'bar' do
    halt "BAR!"
  end

  remainder do |rest|
    halt "Rest was #{rest}"
  end
end
```

Notice this allows you to handle the cases within a particular route scope and manage them based on the "rest" of the uri yielded in the `remainder` block. You
can handle different remainders in all the different path blocks.

**Named Routes**

Once you have defined your routes, you can then "register" a particular path mapping that to a symbol. This is useful for referencing routes without
having to specify the entire path:

```ruby
run Renee::Core.new {
  register(:test, '/test/time')
  register(:test_var, '/test/:id')
}
```

You can then access these using the `path` method in a route or template:

```ruby
path(:test) # => '/test/time'
path(:test_var, :id => 123) # => '/test/123'
```

Using named routes makes referencing and modifying routes within an application much simpler to manage.

## Responding

Responding to a request within a route can be managed with the `respond`, `halt`, `redirect` commands:

**Respond**

The `respond` command makes returning a rack response very explicit, you can respond as if you were constructing a Rack::Response

```ruby
run Renee {
  get { respond!("hello!", 403, "foo" => "bar") }
}
```

or use the block DSL for convenience:

```ruby
run Renee {
  get { respond! { status 403; headers :foo => "bar"; body "hello!" } }
}
```

**Halt**

Halting is the easiest way to render data within a route:

```ruby
run Renee::Core.new {
  get { halt 'easy' }
}
```

This will return a 200 status code and 'easy' as the body. You can also specify status code and header explicitly in the halt response:

```ruby
get { halt [200, {}, 'body'] }
```

This will set the status code to 200, pass no headers and return 'body'. You can also use several variations of halt:

```ruby
# Return just status code
halt 200

# Return status with symbol
halt :not_found

# Return 200 with body
halt "hello!"

# Return 500 with body
halt 500, "hello!"
```

Halt is the most straightforward way to control the response for a request.

**Redirect**

A redirect is a common action within a web route and can be achieved with the convenience method `redirect` command:

```ruby
get {
  halt redirect('/hello')
}
```

You can also specify the status code for the redirect:

```ruby
get {
  halt redirect('/hello', 303)
}
```