# frozen_string_literal: true

require "open-uri"
require "tempfile"

module Feed::FaviconFetchable
  extend ActiveSupport::Concern

  def fetch_favicon!
    self.favicon ||= Favicon.new(feed: self)

    favicon_candidates.each do |uri|
      next unless (image_data = fetch_and_convert_favicon(uri))

      favicon.image = image_data
      favicon.save
      break
    end
  end

  protected

  # テスト可能にするため protected
  def favicon_candidates
    uris = []

    # フィードXMLからアイコンリンクを探す
    uris.concat(extract_favicon_links_from_feed)

    # HTMLページからアイコンリンクを探す
    uris.concat(extract_favicon_links_from_html) if uris.empty?

    # デフォルトの /favicon.ico を追加
    uris << Addressable::URI.join(feedlink, "/favicon.ico").normalize
    uris << Addressable::URI.join(link, "/favicon.ico").normalize

    uris.uniq
  end

  private

  def extract_favicon_links_from_feed
    xml = Fastladder.simple_fetch(feedlink)
    doc = Nokogiri::XML.parse(xml)

    doc.xpath("//link[@href and (@rel='shortcut icon' or @rel='icon')]/@href").map do |href|
      Addressable::URI.join(feedlink, href.text).normalize
    end
  end

  def extract_favicon_links_from_html
    html = Fastladder.simple_fetch(link)
    doc = Nokogiri::HTML.parse(html)

    doc.xpath('//link[@href and (@rel="shortcut icon" or @rel="icon")]/@href').map do |href|
      Addressable::URI.join(link, href.text).normalize
    end
  end

  def fetch_and_convert_favicon(uri)
    response = URI.open(uri.to_s)
    return nil if response.status.last.to_i >= 400

    convert_to_png(response)
  rescue OpenURI::HTTPError, Errno::ENOENT, Errno::ECONNREFUSED, SocketError, Timeout::Error
    nil
  end

  def convert_to_png(response)
    ext = response.meta["content-type"] == "image/vnd.microsoft.icon" ? ".ico" : ".png"
    tmp = Tempfile.new(["favicon", ext])
    tmp.binmode
    tmp.write(response.read)
    tmp.close

    buf = StringIO.new
    image = MiniMagick::Image.open(tmp.path)
    image.resize "16x16"
    image.format "png"
    image.write(buf)
    buf.rewind
    buf.read.force_encoding("ascii-8bit")
  rescue MiniMagick::Invalid, MiniMagick::Error => e
    Rails.logger.error("#{e.class} (#{e.message})")
    nil
  ensure
    tmp&.close!
  end
end
