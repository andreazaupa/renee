require 'renee-core'
require 'renee-render'

require 'renee/version'

class Renee
  class RichCore < Renee::Core
    def initialize(&blk)
      super
    end

    def call(env)
      application_class.new(settings, &application_block).call(env)
    end
    alias_method :[], :call

    def application_class
      @application_class ||= begin
        app_cls = Class.new(Application)
        settings.includes.each { |inc| app_cls.send(:include, inc) }
        app_cls
      end
    end

    class Application < Renee::Core::Application
      include Renee::Render
    end
  end
end

def Renee(&blk)
  Renee::RichCore.new(&blk)
end