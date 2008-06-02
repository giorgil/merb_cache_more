require 'rubygems'
require 'rubygems/specification'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'date'
require 'merb_rake_helper'

PLUGIN = "merb_cache_more"
NAME = "merb_cache_more"
GEM_VERSION = "0.9.4"
AUTHOR = "Ben Chiu"
EMAIL = "bchiu@yahoo.com"
HOMEPAGE = "http://www.merbivore.com"
SUMMARY = "Extends merb-cache to use params, work with pagination, auto-cache all actions and use many key formats"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency('merb-core', '>= 0.9.4')
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{lib,spec}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

namespace :specs do
  ["file", "memory", "memcache", "sequel", "datamapper", "activerecord"].each do |store|
    desc "Run spec with the \"#{store}\" cache store"
    task "#{store}" do
      cwd = Dir.getwd
      Dir.chdir(File.dirname(__FILE__) + "/spec")
      ENV["STORE"] = store
      system("spec --format specdoc --colour merb-cache_spec.rb")
      Dir.chdir(cwd)
    end
  end
end

namespace :doc do
  Rake::RDocTask.new do |rdoc|
    files = ["README", "LICENSE", "lib/**/*.rb"]
    rdoc.rdoc_files.add(files)
    rdoc.main = "README"
    rdoc.title = "merb_cache_more docs"
    rdoc.rdoc_dir = "doc/rdoc"
    rdoc.options << "--line-numbers" << "--inline-source"
  end
end

task :install => [:package] do
  sh %{#{sudo} #{gemx} install pkg/#{NAME}-#{GEM_VERSION} --local --no-update-sources}
end

task :install_frozen => [:package] do
  sh %{#{sudo} #{gemx} install pkg/#{NAME}-#{GEM_VERSION} -i ../../ --local --no-update-sources}
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

namespace :jruby do

  desc "Run :package and install the resulting .gem with jruby"
  task :install => :package do
    sh %{#{sudo} jruby -S gem install #{install_home} pkg/#{NAME}-#{GEM_VERSION}.gem --local --no-rdoc --no-ri}
  end

end
