# Rakefile.rb
# June 19, 2007
#

require 'rubygems'
require 'rake/gempackagetask'

#require 'rake'
#require 'rake/testtask'
#require 'rake/rdoctask'

spec = Gem::Specification.new do |s|
	s.platform          = Gem::Platform::RUBY
        s.name              = "twm-cms-bindings"
        s.version           = "3.0.0"
        s.author            = "Three Wise Men"
        s.email             = "info @nospam@ threewisemen.ca"
        s.summary           = "Binding library for TWM CMS v3 platform"
        s.files             = FileList[ 'lib/*.rb', 'test/*'].to_a
        s.require_path      = "lib"
        s.autorequire       = "memcache-client"
        s.test_files        = Dir.glob('test/*.rb')
        s.has_rdoc          = true
        s.extra_rdoc_files  = ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
	pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
	puts "generated latest version"
end

