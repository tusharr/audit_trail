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

class CreateTrackedModels < ActiveRecord::Migration
  def self.up
    create_table(:tracked_models) do |t|
      t.integer :count
      t.decimal :price, :precision => 14, :scale => 2
      t.string :note
      t.string :untracked_column
      t.boolean :yes_no
      t.date :occurred_on
      t.datetime :occurred_at
    end
  end
  
  def self.down
    drop_table :tracked_models
  end
end


CreateAuditTrails.suppress_messages do
  CreateAuditTrails.migrate( :up )
  CreateTrackedModels.migrate( :up )
end

require 'active_support/all'
require File.expand_path('../../app/models/change_event.rb', __FILE__)


class ActiveSupport::TestCase
  
  private
  
  def declare_tracked_model
    Object.const_set(:TrackedModel, Class.new(ActiveRecord::Base))
  end
  
  def cleanup_tracked_model
    Object.send :remove_const, :TrackedModel
  end
end
