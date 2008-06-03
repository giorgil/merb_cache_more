require File.dirname(__FILE__) + "/spec_helper"

Merb::Router.prepare do |r|
  r.default_routes
  r.match("/").to(:controller => "cache_controller", :action => "index")
end

CACHE = CacheController.new(Merb::Test::RequestHelper::FakeRequest.new)
CACHE.expire_all

puts "Using #{CACHE._cache.store.cache_store_type.inspect} store"

require File.dirname(__FILE__) + "/cache_keys_spec"
require File.dirname(__FILE__) + "/cache_action_spec"
require File.dirname(__FILE__) + "/cache_action_params_spec"
require File.dirname(__FILE__) + "/cache_page_spec"
require File.dirname(__FILE__) + "/cache_page_params_spec"
require File.dirname(__FILE__) + "/cache_fragment_spec"
