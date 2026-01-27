require "test_helper"

class Api::FolderControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "mala", password_confirmation: "mala")
    @folder = create_folder(member: @member)
  end

  test "POST create creates new folder" do
    assert_difference "Folder.count", 1 do
      post :create, params: { name: "便利情報" }, session: { member_id: @member.id }
    end
  end

  test "POST create renders json" do
    post :create, params: { name: "便利情報" }, session: { member_id: @member.id }

    assert_valid_json response.body
  end

  test "POST create renders error without name" do
    post :create, session: { member_id: @member.id }

    assert_json_error response.body
  end

  test "POST delete renders json" do
    post :delete, params: { folder_id: @folder.id }, session: { member_id: @member.id }

    assert_valid_json response.body
  end

  test "POST delete renders error without folder_id" do
    post :delete, session: { member_id: @member.id }

    assert_json_error response.body
  end

  test "POST update renders json" do
    post :update, params: { folder_id: @folder.id, name: "Life Hack" }, session: { member_id: @member.id }

    assert_valid_json response.body
  end

  test "POST update renders error without folder_id" do
    post :update, session: { member_id: @member.id }

    assert_json_error response.body
  end

  test "not logged in renders blank" do
    post :update

    assert_predicate response.body, :blank?
  end

  # Turbo Stream tests
  test "POST create with turbo stream returns turbo stream response" do
    post :create,
         params: { name: "New Folder" },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
    assert_match "manage_folder", response.body
    assert_match "New Folder", response.body
  end

  test "POST create with turbo stream returns error for duplicate folder" do
    @member.folders.create(name: "Existing")

    post :create,
         params: { name: "Existing" },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :unprocessable_entity
  end

  test "POST delete with turbo stream removes folder" do
    post :delete,
         params: { folder_id: @folder.id },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
    assert_match "remove", response.body
    assert_match "folder-#{@folder.id}", response.body
  end

  test "POST delete with turbo stream returns not found for missing folder" do
    post :delete,
         params: { folder_id: 99_999 },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :not_found
  end

  test "POST update with turbo stream replaces folder" do
    post :update,
         params: { folder_id: @folder.id, name: "Updated Name" },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
    assert_match "replace", response.body
    assert_match "Updated Name", response.body
  end

  test "POST update with turbo stream returns not found for missing folder" do
    post :update,
         params: { folder_id: 99_999, name: "New Name" },
         session: { member_id: @member.id },
         as: :turbo_stream

    assert_response :not_found
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

    assert_not json["isSuccess"]
  rescue JSON::ParserError
    flunk "Expected valid JSON, got: #{body}"
  end
end
