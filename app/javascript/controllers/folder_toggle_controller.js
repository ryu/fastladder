import { Controller } from "@hotwired/stimulus"

// Folder Toggle controller - handles folder dropdown in feed header
//
// This controller manages the folder selection dropdown,
// bridging to legacy FolderToggle functions.
//
// Usage:
//   <span data-controller="folder-toggle"
//         data-action="mousedown->folder-toggle#click">
//     Folder Name
//   </span>
//
export default class extends Controller {
  click(event) {
    event.preventDefault()
    event.stopPropagation()

    // Use legacy function if available
    if (typeof FolderToggle !== "undefined" && FolderToggle.click) {
      FolderToggle.click.call(this.element, event)
    } else {
      // Dispatch event for Hotwire handling
      this.dispatch("toggle", { detail: { element: this.element } })
    }
  }
}
