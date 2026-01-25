import { Controller } from "@hotwired/stimulus"

// Menu Item controller - handles menu item interactions
//
// This controller bridges between ERB partials and legacy JavaScript
// for dropdown menu items (view mode, sort mode, folder selection).
//
// Usage:
//   <span data-controller="menu-item"
//         data-menu-item-action-value="view|sort|move"
//         data-menu-item-mode-value="flat"
//         data-action="mouseout->menu-item#unhover mouseover->menu-item#hover mouseup->menu-item#select">
//     Label
//   </span>
//
export default class extends Controller {
  static values = {
    action: String,  // "view", "sort", or "move"
    mode: String,    // mode value for view/sort
    folder: String   // folder name for move action
  }

  hover() {
    this.element.classList.add("hover")
    // Call legacy MenuItem if available
    if (typeof MenuItem !== "undefined" && MenuItem.onhover) {
      MenuItem.onhover.call(this.element, event)
    }
  }

  unhover() {
    this.element.classList.remove("hover")
    if (typeof MenuItem !== "undefined" && MenuItem.onunhover) {
      MenuItem.onunhover.call(this.element, event)
    }
  }

  select(event) {
    const action = this.actionValue

    switch (action) {
      case "view":
        this.changeViewMode()
        break
      case "sort":
        this.changeSortMode()
        break
      case "move":
        this.moveToFolder()
        break
      default:
        console.warn("[MenuItem] Unknown action:", action)
    }

    // Hide menu after selection
    this.hideMenu()
  }

  changeViewMode() {
    const mode = this.modeValue
    if (typeof Control !== "undefined" && Control.change_view) {
      Control.change_view(mode)
    } else {
      // Dispatch event for future Hotwire handling
      this.dispatch("viewModeChanged", { detail: { mode } })
    }
  }

  changeSortMode() {
    const mode = this.modeValue
    if (typeof Control !== "undefined" && Control.change_sort) {
      Control.change_sort(mode)
    } else {
      this.dispatch("sortModeChanged", { detail: { mode } })
    }
  }

  moveToFolder() {
    const folder = this.folderValue
    if (typeof Control !== "undefined" && Control.move_to) {
      Control.move_to(folder)
    } else {
      this.dispatch("folderSelected", { detail: { folder } })
    }
  }

  hideMenu() {
    if (typeof FlatMenu !== "undefined" && FlatMenu.hideAll) {
      FlatMenu.hideAll()
    }
  }
}
