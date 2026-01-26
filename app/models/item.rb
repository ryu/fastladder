# == Schema Information
#
# Table name: items
#
#  id             :integer          not null, primary key
#  feed_id        :integer          default(0), not null
#  link           :string(255)      default(""), not null
#  title          :text             not null
#  body           :text
#  author         :string(255)
#  category       :string(255)
#  enclosure      :string(255)
#  enclosure_type :string(255)
#  digest         :string(255)
#  version        :integer          default(1), not null
#  stored_on      :datetime
#  modified_on    :datetime
#  created_on     :datetime         not null
#  updated_on     :datetime         not null
#

class Item < ApplicationRecord
  belongs_to :feed, optional: true
  validates :guid, presence: true, uniqueness: { scope: :feed_id }

  before_validation :default_values
  before_save :create_digest, :fill_datetime

  scope :stored_since, ->(viewed_on) { viewed_on ? where("stored_on >= ?", viewed_on) : all }
  scope :recent, ->(limit = nil, offset = nil) { order("created_on DESC, id DESC").limit(limit).offset(offset) }

  def default_values
    self.title ||= ""
    self.guid ||= link
  end

  def fill_datetime
    self.stored_on = Time.now unless stored_on
  end

  def create_digest
    str = "#{self.title}#{body}"
    str.gsub!(%r{<br clear="all"\s*/>\s*<a href="http://rss\.rssad\.jp/(.*?)</a>\s*<br\s*/>}im, "")
    str = str.gsub(/\s+/, "")
    digest = Digest::SHA1.hexdigest(str)
    self.digest = digest
  end

  def as_json(_options = {})
    result = {}
    result[:created_on] = created_on ? created_on.to_time.to_i : 0
    result[:modified_on] = modified_on ? modified_on.to_time.to_i : 0
    result[:id] = id
    result[:enclosure_type] = enclosure_type if enclosure_type
    result[:enclosure] = (enclosure || "").purify_uri if enclosure
    %i[title author category].each do |s|
      result[s] = (send(s) || "").purify_html
    end
    result[:link] = (link || "").purify_uri
    result[:body] = (body || "").scrub_html
    result
  end
end
