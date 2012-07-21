# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "audit_trail"
  gem.homepage = "http://github.com/tusharr/audit_trail"
  gem.license = "MIT"
  gem.summary = %Q{track changes to active record objects on an attribute level}
  gem.description = %Q{tracks_changes provides a way to easily keep track of changes to ActiveRecord models at an attribute level and maintains the typecasting in the database.}
  gem.email = "tusharranka@gmail.com"
  gem.authors = ["Tushar Ranka"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

