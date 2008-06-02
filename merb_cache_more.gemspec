Gem::Specification.new do |s|
  s.name = %q{merb_cache_more}
  s.version = "0.9.4"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ben Chiu"]
  s.date = %q{2008-06-02}
  s.description = %q{Extends merb-cache to use params, work with pagination, auto-cache all actions and use many key formats}
  s.email = %q{bchiu@yahoo.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/merb_cache_more", "lib/merb_cache_more/cache-action.rb", "lib/merb_cache_more/cache-fragment.rb", "lib/merb_cache_more/cache-page.rb", "lib/merb_cache_more/cache-store", "lib/merb_cache_more/cache-store/database-activerecord.rb", "lib/merb_cache_more/cache-store/database-datamapper.rb", "lib/merb_cache_more/cache-store/database-sequel.rb", "lib/merb_cache_more/cache-store/database.rb", "lib/merb_cache_more/cache-store/dummy.rb", "lib/merb_cache_more/cache-store/file.rb", "lib/merb_cache_more/cache-store/memcache.rb", "lib/merb_cache_more/cache-store/memory.rb", "lib/merb_cache_more/merb-cache.rb", "lib/merb_cache_more/merbtasks.rb", "lib/merb_cache_more/request.rb", "lib/merb_cache_more/request_helper.rb", "lib/merb_cache_more.rb", "spec/cache_action_params_spec.rb", "spec/cache_action_spec.rb", "spec/cache_controller.rb", "spec/cache_fragment_spec.rb", "spec/cache_keys_spec.rb", "spec/cache_page_params_spec.rb", "spec/cache_page_spec.rb", "spec/config", "spec/config/database.yml", "spec/merb_cache_more_spec.rb", "spec/spec_helper.rb", "spec/views", "spec/views/cache_controller", "spec/views/cache_controller/action1.html.erb", "spec/views/cache_controller/action2.html.haml"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/bchiu/merb_cache_more}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{Extends merb-cache to use params, work with pagination, auto-cache all actions and use many key formats}

  s.add_dependency(%q<merb-core>, [">= 0.9.4"])
end
