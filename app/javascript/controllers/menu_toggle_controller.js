import { Controller } from "@hotwired/stimulus"

// Handles menu toggle button (Others dropdown)
// Replaces inline onselectstart and onmousedown handlers
export default class extends Controller {
  connect() {
    // Prevent text selection on the button
    this.element.style.userSelect = "none"
  }

  toggle(event) {
    // Delegate to existing Control.toggle_menu for backwards compatibility
    if (typeof Control !== "undefined" && Control.toggle_menu) {
      Control.toggle_menu.call(this.element, event)
    }
  }

  // Prevent default selectstart behavior
  preventSelect(event) {
    event.preventDefault()
    return false
  }
}
