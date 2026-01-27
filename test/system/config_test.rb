# frozen_string_literal: true

require "application_system_test_case"

class ConfigTest < ApplicationSystemTestCase
  setup do
    @dankogai = Member.create!(username: "dankogai", password: "kogaidan", password_confirmation: "kogaidan")
    visit "/login"
    fill_in "username", with: "dankogai"
    fill_in "password", with: "kogaidan"
    click_on "Sign In"

    assert_current_path "/reader/"
    assert_text "Loading completed.", wait: 10
  end

  test "can change display config" do
    # Open settings via JavaScript to ensure onclick handler fires
    page.execute_script('init_config()')

    assert_text "Fastladder Settings", wait: 10
    page.execute_script('document.getElementById("tab_config_view").click()')

    assert_text "For shorter loading time, set the limit smaller.", wait: 10

    # Clear and fill the font size field via JavaScript
    page.execute_script('_$("save_current_font").value = "24"')
    # Submit form via JavaScript
    page.execute_script('_$("config_form").submit()')
    sleep 0.5 # Wait for AJAX to complete

    visit "/reader/"

    assert_text "Loading completed.", wait: 10
    # Open settings via JavaScript
    page.execute_script('init_config()')

    assert_text "Fastladder Settings", wait: 10
    page.execute_script('document.getElementById("tab_config_view").click()')

    assert_text "For shorter loading time, set the limit smaller."

    assert_equal "24", find_by_id('save_current_font').value

    dump = nil
    10.times do
      dump = @dankogai.reload.config_dump
      break if dump["current_font"] == "24"

      sleep 0.3
    end

    assert_equal "24", dump["current_font"]
  end
end
