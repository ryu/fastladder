# frozen_string_literal: true

# Helper methods for the Reader page
#
# Provides server-side support for features being migrated from
# legacy JavaScript templates to ERB partials.
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
end
