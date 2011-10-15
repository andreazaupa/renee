# Renee Render

Rendering templates in Renee should be familiar and intuitive using the `render` command:

```ruby
run Renee::Core.new {
 path('blog') do
   get { render! :haml, :"blogs/index" }
 end
}
```

This above is the standard render syntax, specifying the engine followed by the template. You can also render without specifying an engine:

```ruby
path('blog') do
  get { render! "blogs/index" }
end
```

This will do a lookup in the views path to find the appropriately named template. You can also pass locals and layout options as you would expect:

```ruby
path('blog') do
  get { render! "blogs/index", :locals => { :foo => "bar" }, :layout => :bar }
end
```

This will render the "blogs/index.erb" file if it exists, passing the 'foo' local variable
and wrapping the result in the 'bar.erb' layout file. You can also render without returning the response by using:

```ruby
path('blog') do
  get { render "blogs/index" }
end
```

This allows you to render the content as a string without immediately responding.