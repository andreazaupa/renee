require 'tilt'

class Renee
  # This module is responsible for handling the rendering of templates
  # using Tilt supporting all included template engines.
  module Render
    ##
    # Exception responsible for when a generic rendering error occurs.
    #
    class RenderError < RuntimeError; end

    ##
    # Exception responsible for when an expected template does not exist.
    #
    class TemplateNotFound < RenderError; end

    # Same as render but automatically halts.
    # @param  (see #render)
    # @return (see #render)
    # @see #render
    def render!(*args, &blk)
      halt render(*args, &blk)
    end

    ##
    # Renders a string given the engine and the content.
    #
    # @param [Symbol] engine The template engine to use for rendering.
    # @param [String] data The content or file to render.
    # @param [Hash] options The rendering options to pass onto tilt.
    #
    # @return [String] The result of rendering the data with specified engine.
    #
    # @example
    #  render :haml, "%p test" => "<p>test</p>"
    #  render :haml, :index => "<p>test</p>"
    #  render "index" => "<p>test</p>"
    #
    # @api public
    #
    def render(engine, data=nil, options={}, &block)
      # Handles the case where engine is unspecified by shifting the data (i.e render "index")
      engine, data, options = nil, engine.to_sym, data if data.nil? || data.is_a?(Hash)

      options                    ||= {}
      options[:outvar]           ||= '@_out_buf'
      # TODO allow default encoding to be set (as an option)
      options[:default_encoding] ||= "utf-8"

      locals         = options.delete(:locals) || {}
      views          = options.delete(:views)  || settings.views_path || "./views"
      layout         = options.delete(:layout)
      layout_engine  = options.delete(:layout_engine) || engine
      # TODO suppress template errors for layouts?
      # TODO allow content_type to be set with an option to render?
      scope          = options.delete(:scope) || self

      # TODO default layout file convention?
      template       = compile_template(engine, data, options, views)
      output         = template.render(scope, locals, &block)

      if layout # render layout
        # TODO handle when layout is missing better!
        options = options.merge(:views => views, :layout => false, :scope => scope)
        return render(layout_engine, layout, options.merge(:locals => locals)) { output }
      end

      output
    end # render

    ##
    # Constructs a template based on engine, data and options.
    #
    # @param [Symbol] engine The template engine to use for rendering.
    # @param [String] data The content or file to render.
    # @param [Hash] options The rendering options to pass onto tilt.
    # @param [String] views The view_path from which to locate the template.
    #
    # @return [Tilt::Template] The tilt template to render with all required options.
    # @raise  [TemplateNotFound] The template to render could not be located.
    # @raise  [RenderError] The template to render could not be located.
    #
    # @api private
    #
    def compile_template(engine, data, options, views)
      template_cache.fetch engine, data, options do
        if data.is_a?(Symbol) # data is template path
          file_path, engine = find_template(views, data, engine)
          template = Tilt[engine]
          raise TemplateNotFound, "Template engine not found: #{engine}" if template.nil?
          raise TemplateNotFound, "Template '#{data}' not found in '#{views}'!"  unless file_path
          # TODO suppress errors for layouts?
          template.new(file_path, 1, options)
        elsif data.is_a?(String) # data is body string
          # TODO figure out path based on caller file
          path, line  = options[:path] || "caller file", options[:line] || 1
          body = data.is_a?(String) ? Proc.new { data } : data
          template = Tilt[engine]
          raise "Template engine not found: #{engine}" if template.nil?
          template.new(path, line.to_i, options, &body)
        else # data can't be handled
          raise RenderError, "Cannot render data #{data.inspect}."
        end
      end # template_cache.fetch
    end # compile_template

    ##
    # Searches view paths for template based on data and engine with rendering options.
    # Supports finding a template without an engine.
    #
    # @param [String] views The view paths
    # @param [String] name The name of the template
    # @param [Symbol] engine The engine to use for rendering.
    #
    # @return [<String, Symbol>] An array of the file path and the engine.
    #
    # @example
    #  find_template("./views", "index", :erb) => ["path/to/index.erb", :erb]
    #  find_template("./views", "foo")         => ["path/to/index.haml", :haml]
    #
    # @api private
    #
    def find_template(views, name, engine=nil)
      lookup_ext = (engine || File.extname(name.to_s)[1..-1] || "*").to_s
      base_name = name.to_s.chomp(".#{lookup_ext}")
      file_path = Dir[File.join(views, "#{base_name}.#{lookup_ext}")].first
      engine ||= File.extname(file_path)[1..-1].to_sym if file_path
      [file_path, engine]
    end # find_template

    # Maintain Tilt::Cache of the templates.
    def template_cache
      @template_cache ||= Tilt::Cache.new
    end
  end
end