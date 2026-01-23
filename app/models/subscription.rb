# == Schema Information
#
# Table name: subscriptions
#
#  id            :integer          not null, primary key
#  member_id     :integer          default(0), not null
#  folder_id     :integer
#  feed_id       :integer          default(0), not null
#  rate          :integer          default(0), not null
#  has_unread    :boolean          default(FALSE), not null
#  public        :boolean          default(TRUE), not null
#  ignore_notify :boolean          default(FALSE), not null
#  viewed_on     :datetime
#  created_on    :datetime         not null
#  updated_on    :datetime         not null
#

class Subscription < ActiveRecord::Base
  belongs_to :member, optional: true
  belongs_to :feed, optional: true
  belongs_to :folder, optional: true
  before_create :update_public_fields
  after_create  :update_subscribers_count
  after_destroy :update_subscribers_count

  scope :open, -> { where(public: true) }
  scope :has_unread, -> { where(has_unread: true) }
  scope :recent, ->(num) { order("created_on DESC").limit(num) }
  scope :with_unread_count, lambda {
    sql = <<~SQL.squish
      subscriptions.*,
      (SELECT count(0) FROM items
       WHERE feed_id = subscriptions.feed_id
       AND (subscriptions.viewed_on IS NULL OR stored_on >= subscriptions.viewed_on)) AS unread_count
    SQL
    select(sql)
  }

  # 個別更新: パラメータに基づいて設定を適用
  def apply_settings(rate: nil, is_public: nil, folder_id: nil, ignore_notify: nil)
    self.rate = rate if rate && (0..5).cover?(rate)
    self.public = is_public unless is_public.nil?
    self.folder_id = folder_id if folder_id
    self.ignore_notify = ignore_notify unless ignore_notify.nil?
    save if changed?
  end

  def update_public_fields
    self.public ||= false
    true
  end

  delegate :update_subscribers_count, to: :feed
end
