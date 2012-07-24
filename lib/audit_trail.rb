require 'rails'
require 'active_support/dependencies'
require 'audit_trail/engine'

module AuditTrail
  extend ActiveSupport::Autoload
  autoload :Model,      'audit_trail/model'
  autoload :ChangeTracking,      'audit_trail/change_tracking'
end

ActiveRecord::Base.send :include, AuditTrail::ChangeTracking