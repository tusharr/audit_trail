require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'audit_trail'
`mysql -uroot -e 'DROP DATABASE IF EXISTS audit_trail_test; CREATE DATABASE audit_trail_test '`
ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "audit_trail_test", :username => 'root')

require File.expand_path('../../lib/generators/audit_trail/templates/migration.rb', __FILE__)

CreateAuditTrails.suppress_messages do
  CreateAuditTrails.migrate( :up )
end

require 'active_support/all'

class ActiveSupport::TestCase
end
