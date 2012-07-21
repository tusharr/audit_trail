require 'rails/generators/active_record'

module AuditTrail
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration
      
      source_root File.expand_path("../templates", __FILE__)

      desc "Creates the migration file required for audit_trail"
      
      def copy_migrations
        migration_template "migration.rb", "db/migrate/create_audit_trail"
      end  
    end
  end
end
