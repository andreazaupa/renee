# -*- coding: utf-8 -*-

require File.expand_path('../test_helper', __FILE__)

describe Renee::Core::URLGeneration do
  it "should allow registration and generation of paths" do
    r = Renee::Core.new
    r.register(:test, '/test/time')
    r.register(:test_var, '/test/:id')
    assert_equal '/test/time', r.path(:test)
    assert_equal '/test/123', r.path(:test_var, :id => 123)
    assert_equal '/test/123', r.path(:test_var, 123)
  end

  it "should allow registration and generation of urls" do
    r = Renee::Core.new
    r.register(:test, 'http://localhost:8080/test/:time')
    assert_equal 'http://localhost:8080/test/123', r.url(:test, 123)
    assert_equal 'http://localhost:8080/test/654', r.url(:test, :time => '654')
  end

  it "should escape values when generating" do
    r = Renee::Core.new
    r.register(:test, '/:test')
    assert_equal '/f%C3%B8%C3%B8', r.path(:test, "føø")
  end

  it "should encode extra values as query string params" do
    r = Renee::Core.new
    r.register(:test, '/:test')
    assert_equal '/foo?bar=baz', r.path(:test, 'foo', :bar => :baz)
    assert_equal '/foo?bar=baz', r.path(:test, :test => 'foo', :bar => :baz)
  end

  it "should allow default values" do
    r = Renee::Core.new
    r.register(:test, '/:test', :test => 'foo')
    assert_equal '/foo', r.path(:test)
    assert_equal '/baz', r.path(:test, :test => 'baz')
  end

  it "should include default vars as query string vars" do
    r = Renee::Core.new
    r.register(:test, '/:foo', :test => 'foo')
    assert_equal '/foo?test=foo', r.path(:test, 'foo')
    assert_equal '/foo?test=foo', r.path(:test, :foo => 'foo')
  end

  it "should allow #prefix calls for nesting common path parts" do
    r = Renee::Core.new
    r.prefix('/foo') do
      r.register(:foo_bar, '/bar')
    end
    assert_equal '/foo/bar', r.path(:foo_bar)
  end

  it "should allow passing defaults and overriding them on a per-register basis" do
    r = Renee::Core.new
    r.prefix('/foo', :bar => 'baz') do
      register(:foo_bar, '/bar', :bar => 'bam')
      register(:foo_baz, '/baz')
    end
    assert_equal '/foo/bar?bar=bam', r.path(:foo_bar)
    assert_equal '/foo/baz?bar=baz', r.path(:foo_baz)
  end
end