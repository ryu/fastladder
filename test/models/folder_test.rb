require "test_helper"

class FolderTest < ActiveSupport::TestCase
  test "belongs to member" do
    member = create_member
    folder = create_folder(member: member)

    assert_equal member, folder.member
  end

  test "has many subscriptions" do
    folder = create_folder
    subscription1 = create_subscription(folder: folder)
    subscription2 = create_subscription(folder: folder)

    assert_includes folder.subscriptions, subscription1
    assert_includes folder.subscriptions, subscription2
  end

  test "has many feeds through subscriptions" do
    folder = create_folder
    feed1 = create_feed
    feed2 = create_feed
    create_subscription(folder: folder, feed: feed1)
    create_subscription(folder: folder, feed: feed2)

    assert_includes folder.feeds, feed1
    assert_includes folder.feeds, feed2
  end

  test "destroying folder nullifies subscriptions" do
    folder = create_folder
    subscription = create_subscription(folder: folder)
    folder.destroy
    subscription.reload

    assert_nil subscription.folder_id
  end

  test "name must be unique per member" do
    member = create_member
    create_folder(member: member, name: "Tech")
    duplicate = Folder.new(member: member, name: "Tech")
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
  end

  test "same name allowed for different members" do
    member1 = create_member
    member2 = create_member
    create_folder(member: member1, name: "Tech")
    folder2 = Folder.new(member: member2, name: "Tech")

    assert folder2.save
  end
end
