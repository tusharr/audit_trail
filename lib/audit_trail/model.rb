module AuditTrail
  module Model
    extend ActiveSupport::Concern
    
    included do
      belongs_to :changed_object, :polymorphic => true
      # belongs_to :created_by, :class_name => 'User'
      validates_presence_of :changed_attribute, :changed_object
    end
    
    module ClassMethods
      def changer
      end
      
      def changer_ip_address
      end
    end
    
    def value
      send("#{change_type}_value")
    end
    
    def previous_value
      send("previous_#{change_type}_value")
    end
    
    def change_type
      @change_type ||= changed_object.class.audit_trail_types[changed_attribute.to_s]
    end
  end
end