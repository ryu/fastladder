import { Controller } from "@hotwired/stimulus"

// Handles folder toggle in feed header template
// Replaces inline onselectstart/onmousedown handlers
export default class extends Controller {
  connect() {
    // Prevent text selection on the button
    this.element.style.userSelect = "none"
  }

  toggle(event) {
    event.preventDefault()
    // Delegate to existing FolderToggle.click for backwards compatibility
    if (typeof FolderToggle !== "undefined" && FolderToggle.click) {
      FolderToggle.click.call(this.element, event)
    }
    return false
  }

  preventSelect(event) {
    event.preventDefault()
    return false
  }
}
