require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "methodical"
    gem.summary = %Q{Automation framework for sequential operations}
    gem.description = %Q{Sorry, no description yet}
    gem.email = "avdi@avdi.org"
    gem.homepage = "http://github.com/avdi/methodical"
    gem.authors = ["Avdi Grimm"]
    gem.add_dependency "extlib", "~> 0.9.14"
    gem.add_dependency "arrayfields", "~> 4.7"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "mocha", "~> 0.9.8"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_files += FileList['test/**/*_test.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "methodical #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
