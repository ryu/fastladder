require "test_helper"

class Api::PinControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "mala", password_confirmation: "mala")
  end

  test "POST all renders json" do
    3.times { create_pin(member: @member) }
    post :all, session: { member_id: @member.id }

    assert_valid_json response.body
  end

  test "POST all renders purified link" do
    create_pin(member: @member, link: "http://www.example.com/get?x=1&y=2")
    post :all, session: { member_id: @member.id }
    json = response.parsed_body

    assert_includes json.last["link"], "&amp;"
  end

  test "POST add renders json" do
    post :add, params: { link: "http://la.ma.la/blog/diary_200810292006.htm", title: "近況" }, session: { member_id: @member.id }

    assert_valid_json response.body
  end

  test "POST add renders error without link" do
    post :add, session: { member_id: @member.id }
    error = { "isSuccess" => false, "ErrorCode" => 1 }

    assert_equal error, response.parsed_body
  end

  test "POST remove renders json" do
    post :remove, params: { link: "http://la.ma.la/blog/diary_200810292006.htm" }, session: { member_id: @member.id }

    assert_valid_json response.body
  end

  test "POST remove renders error without link" do
    post :remove, session: { member_id: @member.id }

    assert_json_error response.body
  end

  test "POST remove returns error code when pin not found" do
    post :remove, params: { link: "http://la.ma.la/blog/diary_200810292006.htm" }, session: { member_id: @member.id }
    json = response.parsed_body

    assert_includes json, "ErrorCode"
    assert_equal Api::PinController::ErrorCode::NOT_FOUND, json["ErrorCode"]
  end

  test "POST remove returns success when pin exists" do
    link = "http://la.ma.la/blog/diary_200810292006.htm"
    create_pin(member: @member, link: link)
    post :remove, params: { link: link }, session: { member_id: @member.id }
    json = response.parsed_body

    assert_includes json, "isSuccess"
    assert json["isSuccess"], "Expected isSuccess to be true"
  end

  test "POST clear renders json" do
    create_pin(member: @member)
    post :clear, session: { member_id: @member.id }

    assert_valid_json response.body
  end

  test "POST clear deletes all pins" do
    create_pin(member: @member)
    assert_changes -> { @member.pins.count }, from: 1, to: 0 do
      post :clear, session: { member_id: @member.id }
    end
  end

  test "not logged in renders blank" do
    post :clear

    assert_predicate response.body, :blank?
  end

  # Turbo Stream tests
  test "POST add returns turbo_stream when requested" do
    post :add,
         params: { link: "http://example.com/article", title: "Test Article" },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "pin-count"
  end

  test "POST remove returns turbo_stream when requested" do
    link = "http://example.com/to-remove"
    pin = create_pin(member: @member, link: link, title: "Remove Me")

    post :remove,
         params: { link: link },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "pin-#{pin.id}"
  end

  test "POST clear returns turbo_stream when requested" do
    create_pin(member: @member)
    create_pin(member: @member, link: "http://example.com/2")

    post :clear,
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "pins-list"
  end

  private

  def assert_valid_json(body)
    result = JSON.parse(body)

    assert_not_nil result, "Expected valid JSON, got: #{body}"
  rescue JSON::ParserError => e
    flunk "Expected valid JSON: #{e.message}"
  end

  def assert_json_error(body)
    json = JSON.parse(body)

    assert_equal false, json["isSuccess"]
  rescue JSON::ParserError
    flunk "Expected valid JSON, got: #{body}"
  end
end
