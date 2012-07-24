require 'test_helper'

class ChangeTrackingTest < ActiveSupport::TestCase
  
  setup :declare_tracked_model
  teardown :cleanup_tracked_model
  
  def test_methods_defined
    assert TrackedModel.respond_to?(:audit_trail_for)
  end
  
  def test_audit_trail_for
    TrackedModel.class_eval do
      audit_trail_for :count, :price
    end
    
    obj = TrackedModel.new

    assert obj.respond_to?(:record_change_event_for_count)
    assert obj.respond_to?(:record_change_event_for_price)
    
    assert_equal :integer, TrackedModel.audit_trail_types['count']
    assert_equal :decimal, TrackedModel.audit_trail_types['price']

  end

  def test_record_change_events__changes_on_non_tracked_attributes
    TrackedModel.class_eval do
      audit_trail_for :note
    end
    
    obj = TrackedModel.new
    obj.untracked_column = "foobar"

    assert_no_difference 'ChangeEvent.count' do
      obj.save!
    end
  end
  
  def test_record_change_events__changes_on_tracked_attributes
    TrackedModel.class_eval do
      audit_trail_for :note, :price
    end
    
    obj = TrackedModel.new(:note => "value_new")
    
    assert_difference 'ChangeEvent.count', 1 do
      obj.save!
    end

    change_event = ChangeEvent.last
    assert_equal nil, change_event.previous_string_value
    assert_equal 'value_new', change_event.string_value
    assert_equal 'note', change_event.changed_attribute
    assert_equal obj, change_event.changed_object
    assert change_event.additional_info.blank?
    assert_equal nil, change_event.previous_value
    assert_equal 'value_new', change_event.value
    
    assert_no_difference 'ChangeEvent.count' do
      obj.save!
    end
    
    assert_difference 'ChangeEvent.count', 2 do
      obj.update_attributes!(:note => "new_new_value", :price => 100.00)
    end
    
    note_change_event = ChangeEvent.where(:changed_attribute => "note").last

    assert_equal 'value_new', note_change_event.previous_string_value
    assert_equal 'new_new_value', note_change_event.string_value
    assert_equal 'note', note_change_event.changed_attribute
    assert_equal obj, note_change_event.changed_object
    assert note_change_event.additional_info.blank?
    assert_equal 'value_new', note_change_event.previous_value
    assert_equal 'new_new_value', note_change_event.value


    price_change_event = ChangeEvent.where(:changed_attribute => "price").last
    assert_equal nil, price_change_event.previous_decimal_value
    assert_equal 100.00, price_change_event.decimal_value
    assert_equal 'price', price_change_event.changed_attribute
    assert_equal obj, price_change_event.changed_object
    assert price_change_event.additional_info.blank?
    assert_equal nil, price_change_event.previous_value
    assert_equal 100.00, price_change_event.value
  end

  def test_record_change_events__changes_on_tracked_attributes__with_additional_info
    TrackedModel.class_eval do
      audit_trail_for :note, :additional_info => :note_additional_info
      audit_trail_for :price, :additional_info => Proc.new { |rec| "Price: #{rec.price}"}
      
      def note_additional_info
        "note"
      end
    end
    
    obj = TrackedModel.create(:note => 'old_value', :price => 1)
    obj.note = "new_note"
    obj.price = 10

    assert_difference 'ChangeEvent.count', 2 do
      obj.save!
    end

    note_change_event = obj.note_change_events.first
    price_change_event = obj.price_change_events.first

    assert_equal 'old_value', note_change_event.previous_value
    assert_equal 'new_note', note_change_event.value
    assert_equal 'note', note_change_event.changed_attribute
    assert_equal obj, note_change_event.changed_object
    assert_equal 'note', note_change_event.additional_info
    
    assert_equal 1, price_change_event.previous_value
    assert_equal 10, price_change_event.value
    assert_equal 'price', price_change_event.changed_attribute
    assert_equal obj, price_change_event.changed_object
    assert_equal "Price: 10.0", price_change_event.additional_info
  end

  def test_record_change_events__changes_on_tracked_attributes__if_block
    TrackedModel.class_eval do
      audit_trail_for :note, :if => :some_check
    end
    
    obj = TrackedModel.new(:note => "old_value")
    obj.stubs(:some_check).returns(true)
    obj.save!

    obj.note = "new_note"

    assert_difference 'ChangeEvent.count', 1 do
      obj.save!
    end

    note_change_event = ChangeEvent.last
    assert_equal 'old_value', note_change_event.previous_value
    assert_equal 'new_note', note_change_event.value
    assert_equal 'note', note_change_event.changed_attribute
    assert_equal obj, note_change_event.changed_object
    
    obj.stubs(:some_check).returns(false)

    assert_no_difference 'ChangeEvent.count' do
      obj.update_attributes!(:note => 'new_new_note')
    end
  end

  def test_record_change_events__changes_on_tracked_attributes__if_block_separate_statements_for_each_attr
    TrackedModel.class_eval do
      audit_trail_for :note, :if => :some_check_1
      audit_trail_for :price, :if => Proc.new { |rec| rec.some_check_2 }
    end
    
    obj = TrackedModel.new
    obj.stubs(:some_check_1).returns(true)
    obj.stubs(:some_check_2).returns(false)
    
    obj.note = "new_note"
    obj.price = 1

    assert_difference 'obj.note_change_events.count', 1 do
      assert_no_difference 'obj.price_change_events.count' do
        obj.save!
      end
    end

    obj.stubs(:some_check_1).returns(false)
    obj.stubs(:some_check_2).returns(true)

    obj.note = "new_new_note"
    obj.price = 100
    
    assert_no_difference 'obj.note_change_events.count' do
      assert_difference 'obj.price_change_events.count', 1 do
        obj.save!
      end
    end
  end
  
  def test_change_events__different_types
    TrackedModel.class_eval do
      audit_trail_for :note, :price, :yes_no, :occurred_on, :occurred_at, :count
    end
    
    obj = TrackedModel.new
    obj.attributes = { :note => "new_note", :price => 10, :yes_no => true, :occurred_at => Time.now, :occurred_on => Date.today, :untracked_column => "hello", :count => 1 }
    
    assert_difference 'ChangeEvent.count', 6 do
      obj.save!
    end
    
    assert_change_event obj.note_change_events.first, 'note', nil, "new_note", :string
    assert_change_event obj.price_change_events.first, 'price', nil, 10, :decimal
    assert_change_event obj.count_change_events.first, 'count', nil, 1, :integer
    assert_change_event obj.yes_no_change_events.first, 'yes_no', nil, true, :boolean
    assert_change_event obj.occurred_on_change_events.first, 'occurred_on', nil, Date.today, :date
  end
  
  def test_change_events__records_user
    TrackedModel.class_eval do
      audit_trail_for :note
    end
    ChangeEvent.stubs(:changer).returns(stub(:id => 5))

    obj = TrackedModel.new(:note => 'note')
    obj.save!
    
    changed_event = ChangeEvent.last
    assert_equal 5, changed_event.changed_by_id
  end
  
  def test_change_events__records_ip_address
    TrackedModel.class_eval do
      audit_trail_for :note
    end

    ChangeEvent.stubs(:changer_ip_address).returns("3.4.5.6")

    obj = TrackedModel.new(:note => 'note')
    obj.save!
    
    changed_event = ChangeEvent.last
    assert_equal "3.4.5.6", changed_event.changer_ip_address
  end
  
  def test_change_events__supports_different_callbacks
    TrackedModel.class_eval do
      audit_trail_for :note
      audit_trail_for :price, :on => :update
    end
    
    obj = TrackedModel.new

    assert_difference 'obj.note_change_events.count', 1 do
      assert_no_difference 'obj.price_change_events.count' do
        obj.update_attributes!(:note => 'note', :price => 1)
      end
    end
    
    assert_difference 'obj.note_change_events.count', 1 do
      assert_difference 'obj.price_change_events.count', 1 do
        obj.update_attributes!(:note => 'note2', :price => 100)
      end
    end
    
    assert_no_difference 'obj.note_change_events.count' do
      assert_no_difference 'obj.price_change_events.count' do
        obj.update_attributes!(:note => 'note2', :price => 100)
      end
    end
    
    
  end
  
  

  private
  
  def assert_change_event(change_event, changed_attribute, previous_value, new_value, type)
    assert_equal changed_attribute, change_event.changed_attribute
    assert_equal previous_value, change_event.previous_value
    assert_equal new_value, change_event.value
    assert_equal previous_value, change_event.send("previous_#{type}_value")
    assert_equal new_value, change_event.send("#{type}_value")
  end
  
end
