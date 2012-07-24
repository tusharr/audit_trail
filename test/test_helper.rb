ENV['RAILS_ENV'] = 'test'
require "test_app_#{ENV['TEST_VERSION'] || '3_1'}/config/environment"

require "rails/test_help"
require 'mocha'
require 'pp'

# Re-create test database
`mysql -uroot -e 'DROP DATABASE IF EXISTS audit_trail_test; CREATE DATABASE audit_trail_test '`

# Define connection configuration
ActiveRecord::Base.configurations = {
    'test' => {
        'adapter'  => 'mysql2',
        'username' => 'root',
        'encoding' => 'utf8',
        'database' => 'audit_trail_test',
    }
}

ActiveRecord::Base.establish_connection 'test'

require 'audit_trail'

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
