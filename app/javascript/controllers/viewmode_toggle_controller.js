import { Controller } from "@hotwired/stimulus"

// Handles viewmode toggle button
// Replaces inline onselectstart and onmousedown handlers
export default class extends Controller {
  connect() {
    // Prevent text selection on the button
    this.element.style.userSelect = "none"
  }

  toggle(event) {
    event.preventDefault()
    // Delegate to existing ViewmodeToggle.click for backwards compatibility
    if (typeof ViewmodeToggle !== "undefined" && ViewmodeToggle.click) {
      ViewmodeToggle.click.call(this.element, event)
    }
    return false
  }

  // Prevent default selectstart behavior
  preventSelect(event) {
    event.preventDefault()
    return false
  }
}
