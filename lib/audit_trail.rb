require 'active_record'
require 'active_support/dependencies'

module AuditTrail
  extend ActiveSupport::Autoload
  autoload :Model,      'audit_trail/model'
  autoload :ChangeTracking,      'audit_trail/change_tracking'
end

ActiveRecord::Base.send :include, AuditTrail::ChangeTracking