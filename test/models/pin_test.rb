require "test_helper"

class PinTest < ActiveSupport::TestCase
  test "after_create runs successfully" do
    member = members(:bulkneets)
    pin = Pin.new(member: member, link: "http://example.com/pin", title: "title")
    assert pin.save
  end

  test "destroy_over_limit_pins does nothing when not over limit" do
    Settings.stub :save_pin_limit, 1 do
      member = create_member
      old_pin = create_pin(member: member, link: "link_1")
      pin = Pin.new(member: member, link: "link_2", title: "title")
      pin.destroy_over_limit_pins
      assert_nothing_raised { old_pin.reload }
    end
  end

  test "destroy_over_limit_pins destroys older pin when over limit" do
    Settings.stub :save_pin_limit, 1 do
      member = create_member
      old_pin = create_pin(member: member, link: "link_1")
      pin = create_pin(member: member, link: "link_2")
      assert_raises(ActiveRecord::RecordNotFound) { old_pin.reload }
      assert_nothing_raised { pin.reload }
    end
  end
end
