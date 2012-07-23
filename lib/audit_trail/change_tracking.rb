module AuditTrail
  module ChangeTracking
    extend ActiveSupport::Concern

    included do
      class_attribute :audit_trail_types
      self.audit_trail_types = (self.audit_trail_types ? self.audit_trail_types.dup : {})
    end

    module ClassMethods
      def audit_trail_for(*attrs)
        options                = attrs.extract_options!
        callback_event         = options.delete(:on) || :save
        additional_info_method = options.delete(:additional_info)
        if_method              = options.delete(:if)

        attrs.each do |attr|
          callback_method_name = :"record_change_event_for_#{attr}"
          tracked_column_type = self.columns.find { |column| column.name.to_s == attr.to_s }.type
          self.audit_trail_types[attr.to_s] = tracked_column_type
          
          if additional_info_method
            define_method :"#{attr}_change_additional_info" do
              if additional_info_method.is_a?(Symbol)
                send(additional_info_method)
              elsif additional_info_method.respond_to?(:call)
                additional_info_method.call(self)
              end
            end
          end

          define_method callback_method_name do
            return unless send(:"#{attr}_changed?")
            change       = send(:"#{attr}_change")

            change_event_attrs = {
              :changed_object    => self,
              :changed_attribute => attr,
            }

            change_event_attrs[:additional_info] = send(:"#{attr}_change_additional_info") if additional_info_method
            change_event_attrs["previous_#{tracked_column_type}_value"] = change.first
            change_event_attrs["#{tracked_column_type}_value"]          = change.last
            change_event = ChangeEvent.new(change_event_attrs)
            change_event.save!
          end
          
          send(:"after_#{callback_event}", callback_method_name, :if => if_method)

          has_many :"#{attr}_change_events",
            :dependent  => :destroy,
            :class_name => "ChangeEvent",
            :as         => :changed_object,
            :order      => "change_events.created_at DESC, change_events.id DESC",
            :conditions => "change_events.changed_attribute = '#{attr}'"

        end
      end
    end
  end
end