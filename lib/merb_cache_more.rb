if defined?(Merb::Plugins)
  require 'merb_cache_more/merb-cache.rb'
  require 'merb_cache_more/cache-action.rb'
  require 'merb_cache_more/cache-page.rb'
  require "merb_cache_more/cache-fragment"
  require 'merb_cache_more/request.rb'
  require 'merb_cache_more/request_helper.rb'
  require "digest/md5"

  unless 1.respond_to? :minutes
    class Numeric
      def minutes; self * 60; end
      def from_now(now = Time.now); now + self; end
    end
  end

  module Merb
    class Controller
      cattr_reader :_cache
      @@_cache = Merb::Cache.new
      include Merb::Cache::ControllerInstanceMethods
      class << self
        include Merb::Cache::ControllerClassMethods
      end
    end
  end

  Merb::BootLoader.after_app_loads do
    Merb::Controller._cache.start
  end

  Merb::Plugins.add_rakefiles "merb_cache_more/merbtasks"
end
