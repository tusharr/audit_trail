class CreateAuditTrails < ActiveRecord::Migration
  def self.up
    create_table(:change_events) do |t|
      t.integer :changed_object_id, :changed_by_id, :integer_value, :previous_integer_value
      t.string  :changed_object_type, :changed_attribute, :string_value, :previous_string_value, :additional_info
      t.date    :date_value, :previous_date_value
      t.datetime :created_at, :datetime_value, :previous_datetime_value
      t.decimal  :decimal_value, :previous_decimal_value, :precision => 14, :scale => 2
      t.boolean  :boolean_value, :previous_boolean_value
    end
  end
  
  def self.down
    drop_table :change_events
  end
end
