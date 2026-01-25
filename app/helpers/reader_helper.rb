# frozen_string_literal: true

# Helper methods for the Reader page
#
# Provides server-side support for features being migrated from
# legacy JavaScript templates to ERB partials.
#
# rubocop:disable Metrics/ModuleLength
module ReaderHelper
  # View mode options for the subscription list
  VIEW_MODES = {
    "flat" => "Flat",
    "folder" => "Folder",
    "rate" => "Rate",
    "subscribers" => "Subscribers"
  }.freeze

  # Sort mode options for the subscription list
  SORT_MODES = {
    "modified_on" => "New Arrival (↓)",
    "modified_on:reverse" => "New Arrival (↑)",
    "unread_count" => "Unread (↓)",
    "unread_count:reverse" => "Unread (↑)",
    "title:reverse" => "A-Z",
    "rate" => "Rating",
    "subscribers_count" => "Subscribers (↓)",
    "subscribers_count:reverse" => "Subscribers (↑)"
  }.freeze

  # Render a view mode menu item
  #
  # @param mode [String] the view mode identifier
  # @param current_mode [String] the currently selected mode
  # @return [String] rendered HTML for the menu item
  def render_viewmode_item(mode, current_mode = nil)
    render partial: "reader/templates/viewmode_item",
           locals: {
             mode: mode,
             label: VIEW_MODES[mode] || mode.titleize,
             checked: mode == current_mode
           }
  end

  # Render all view mode menu items
  #
  # @param current_mode [String] the currently selected mode
  # @return [String] rendered HTML for all menu items
  def render_viewmode_menu(current_mode = nil)
    safe_join(VIEW_MODES.keys.map { |mode| render_viewmode_item(mode, current_mode) })
  end

  # Render a sort mode menu item
  #
  # @param mode [String] the sort mode identifier
  # @param current_mode [String] the currently selected mode
  # @return [String] rendered HTML for the menu item
  def render_sortmode_item(mode, current_mode = nil)
    render partial: "reader/templates/sortmode_item",
           locals: {
             mode: mode,
             label: SORT_MODES[mode] || mode.titleize,
             checked: mode == current_mode
           }
  end

  # Render all sort mode menu items
  #
  # @param current_mode [String] the currently selected mode
  # @return [String] rendered HTML for all menu items
  def render_sortmode_menu(current_mode = nil)
    safe_join(SORT_MODES.keys.map { |mode| render_sortmode_item(mode, current_mode) })
  end

  # Render a folder item for the folder selection menu
  #
  # @param folder [Folder] the folder object
  # @param current_folder [Folder, nil] the currently selected folder
  # @return [String] rendered HTML for the folder item
  def render_folder_item(folder, current_folder = nil)
    folder_name = folder.respond_to?(:name) ? folder.name : folder.to_s
    move_to = folder.respond_to?(:name) ? folder.name : folder.to_s

    render partial: "reader/templates/folder_item",
           locals: {
             folder_name: folder_name,
             move_to: move_to,
             checked: current_folder && current_folder == folder
           }
  end

  # Render the subscribe folder display in the sidebar
  #
  # @param folder [Folder] the folder object
  # @param unread_count [Integer] number of unread items
  # @param classname [String, nil] optional CSS class name
  # @return [String] rendered HTML
  def render_subscribe_folder(folder, unread_count: 0, classname: nil)
    folder_name = folder.respond_to?(:name) ? folder.name : folder.to_s

    render partial: "reader/templates/subscribe_folder",
           locals: {
             name: folder_name,
             unread_count: unread_count,
             classname: classname
           }
  end

  # Render the clip register message
  #
  # @return [String] rendered HTML
  def render_clip_register
    render partial: "reader/templates/clip_register"
  end

  # --- Tier 2 Templates ---

  # Render a generic menu item (for "Others" dropdown)
  #
  # @param title [String] the menu item label
  # @param action [String] JavaScript code to execute on click
  # @return [String] rendered HTML
  def render_menu_item(title:, action:)
    render partial: "reader/templates/menu_item",
           locals: {
             title: title,
             action: action
           }
  end

  # Render a pin item for the pin dropdown
  #
  # @param pin [Pin] the pin object or hash with :title, :link, :icon
  # @param target [Boolean] whether this pin is within the open limit
  # @return [String] rendered HTML
  def render_pin_item(pin, target: false)
    title = pin.respond_to?(:title) ? pin.title : pin[:title]
    link = pin.respond_to?(:link) ? pin.link : pin[:link]
    icon = if pin.respond_to?(:icon)
             pin.icon.presence || "/img/icon/default.gif"
           else
             pin[:icon].presence || "/img/icon/default.gif"
           end

    render partial: "reader/templates/pin_item",
           locals: {
             title: title,
             link: link,
             icon: icon,
             target: target
           }
  end

  # Render a subscription item for the sidebar
  #
  # @param subscription [Subscription] the subscription object
  # @param unread_count [Integer] number of unread items (defaults to 0)
  # @param classname [String, nil] optional CSS class
  # @return [String] rendered HTML
  def render_subscribe_item(subscription, unread_count: 0, classname: nil)
    icon = if subscription.feed&.favicon&.icon_data_uri.present?
             subscription.feed.favicon.icon_data_uri
           else
             "/img/icon/default.gif"
           end

    render partial: "reader/templates/subscribe_item",
           locals: {
             subscription: subscription,
             icon: icon,
             unread_count: unread_count,
             classname: classname
           }
  end

  # Render all subscriptions for a member with unread counts
  #
  # @param subscriptions [Array<Subscription>] subscriptions with unread counts
  # @return [String] rendered HTML for all subscription items
  def render_subscription_list(subscriptions)
    safe_join(subscriptions.map { |sub| render_subscribe_item(sub, unread_count: sub.unread_count || 0) })
  end

  # --- Tier 3 Templates ---

  # Render a discover item (feed in discovery results)
  #
  # @param feed [Hash] feed info with :feedlink, :link, :title, :subscribers_count
  # @param subscribed [Boolean] whether the user is already subscribed
  # @return [String] rendered HTML
  def render_discover_item(feed, subscribed: false)
    render partial: "reader/templates/discover_item",
           locals: {
             feed: feed,
             subscribed: subscribed
           }
  end

  # Render the ads body container
  #
  # @param items [String] rendered ad items HTML
  # @return [String] rendered HTML
  def render_ads_body(items: "")
    render partial: "reader/templates/ads_body",
           locals: { items: items }
  end

  # Render an ad item (currently empty/unused)
  #
  # @param url [String] ad URL
  # @param title [String] ad title
  # @param domain [String] ad domain
  # @return [String] rendered HTML
  def render_ads_item(url:, title:, domain:)
    render partial: "reader/templates/ads_item",
           locals: {
             url: url,
             title: title,
             domain: domain
           }
  end

  # --- Tier 4 Templates ---

  # Render the inbox feed header (channel info)
  #
  # @param feed [Hash] feed data with :link, :title, :description, :image, :folder, :rate, :subscribe_id, :widgets, :items
  # @return [String] rendered HTML
  def render_inbox_feed(feed)
    render partial: "reader/templates/inbox_feed",
           locals: { feed: feed }
  end

  # Render the inbox ad feed header (sponsor feed)
  #
  # @param feed [Hash] feed data with :link, :title, :description, :image, :feedlink, :ads_expire, :items
  # @return [String] rendered HTML
  def render_inbox_adfeeds(feed)
    render partial: "reader/templates/inbox_adfeeds",
           locals: { feed: feed }
  end

  # Render an inbox item (feed entry)
  #
  # @param item [Hash/Item] item data
  # @param item_count [Integer] item index in the list
  # @param loop_context [String] CSS class for odd/even styling
  # @param pinned [Boolean] whether the item is pinned
  # @param pin_active [String] CSS class for pin state
  # @return [String] rendered HTML
  def render_inbox_item(item, item_count: 0, loop_context: "", pinned: false, pin_active: "pin_inactive")
    render partial: "reader/templates/inbox_item",
           locals: {
             item: item,
             item_count: item_count,
             loop_context: loop_context,
             pinned: pinned,
             pin_active: pin_active
           }
  end

  # Render clip info display
  #
  # @param public_clip_count [Integer] number of public clips
  # @param link [String] the clipped URL
  # @param created_on [Time] when the clip was created
  # @return [String] rendered HTML
  def render_clip_info(public_clip_count:, link:, created_on:)
    render partial: "reader/templates/clip_info",
           locals: {
             public_clip_count: public_clip_count,
             link: link,
             created_on: created_on
           }
  end

  # Render the clip form
  #
  # @param item [Hash] item data with :id, :title, :link, :tags, :notes
  # @return [String] rendered HTML
  def render_clip_form(item)
    render partial: "reader/templates/clip_form",
           locals: { item: item }
  end

  # Helper to generate clip page link
  #
  # @param link [String] the URL to clip
  # @return [String] the clip page URL
  def clip_page_link(link)
    "http://clip.livedoor.com/page/#{ERB::Util.url_encode(link)}"
  end
end
# rubocop:enable Metrics/ModuleLength
