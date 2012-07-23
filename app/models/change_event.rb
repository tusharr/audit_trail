class ChangeEvent < ActiveRecord::Base
  include AuditTrail::Model
end
