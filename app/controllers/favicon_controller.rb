class FaviconController < ApplicationController
  def get
    image = nil
    feed_id = url_from_path(:feed)
    feed = /^\d+$/.match?(feed_id) ? Feed.find_by(id: feed_id.to_i) : Feed.find_by(feedlink: feed_id)
    if feed&.favicon
      image = feed.favicon.image
    else
      File.open(Settings.default_favicon) do |f|
        image = f.binmode.read
      end
    end
    send_data image, filename: "favicon", type: "image/png", disposition: "inline"
  end
end
