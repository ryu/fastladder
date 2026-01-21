require "test_helper"

class FolderTest < ActiveSupport::TestCase
  test "belongs to member" do
    member = FactoryBot.create(:member, password: "test", password_confirmation: "test")
    folder = FactoryBot.create(:folder, member: member)
    assert_equal member, folder.member
  end

  test "has many subscriptions" do
    folder = FactoryBot.create(:folder)
    subscription1 = FactoryBot.create(:subscription, folder: folder)
    subscription2 = FactoryBot.create(:subscription, folder: folder)
    assert_includes folder.subscriptions, subscription1
    assert_includes folder.subscriptions, subscription2
  end

  test "has many feeds through subscriptions" do
    folder = FactoryBot.create(:folder)
    feed1 = FactoryBot.create(:feed)
    feed2 = FactoryBot.create(:feed)
    FactoryBot.create(:subscription, folder: folder, feed: feed1)
    FactoryBot.create(:subscription, folder: folder, feed: feed2)
    assert_includes folder.feeds, feed1
    assert_includes folder.feeds, feed2
  end

  test "destroying folder nullifies subscriptions" do
    folder = FactoryBot.create(:folder)
    subscription = FactoryBot.create(:subscription, folder: folder)
    folder.destroy
    subscription.reload
    assert_nil subscription.folder_id
  end

  test "name must be unique per member" do
    member = FactoryBot.create(:member, password: "test", password_confirmation: "test")
    FactoryBot.create(:folder, member: member, name: "Tech")
    duplicate = Folder.new(member: member, name: "Tech")
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
  end

  test "same name allowed for different members" do
    member1 = FactoryBot.create(:member, username: "user1", password: "test", password_confirmation: "test")
    member2 = FactoryBot.create(:member, username: "user2", password: "test", password_confirmation: "test")
    folder1 = FactoryBot.create(:folder, member: member1, name: "Tech")
    folder2 = Folder.new(member: member2, name: "Tech")
    assert folder2.save
  end
end
