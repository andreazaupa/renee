require 'rubygems'
require 'benchmark'

$: << 'lib'
require 'renee'

router = Renee::Core.new {
  path 'test/time' do
    query_string 'ok' do
      get { halt "ok" }
      post { halt [200, {}, ['POSTED!']] }
    end
  end
  variable do |id1, id2|
    path 'more' do
      get {
        halt [200, {}, "this is the id1: #{id1} id2: #{id2}" ]
      }
    end
  end
  remainder do |rest|
    halt "the rest is #{rest}"
  end
}.setup {
  view_path('views')
  environment(:development)
}

app = Renee do
  path "add" do
    variable Integer do |first, second|
      "#{first} + #{second} = #{first + second}"
    end
  end
end

p router.call(Rack::MockRequest.env_for('/add/3/4')) # => "3 + 4 = 7"

p router.call(Rack::MockRequest.env_for('/test/time?ok'))
p router.call(Rack::MockRequest.env_for('/test/josh/more'))
p router.call(Rack::MockRequest.env_for('/'))


#puts Benchmark.measure {
  #50_000.times do
#    router.call(Rack::MockRequest.env_for('/test/josh/more'))
    #router.call(Rack::MockRequest.env_for('/test/time?ok', :method => 'POST' ))  
  #end
#}
