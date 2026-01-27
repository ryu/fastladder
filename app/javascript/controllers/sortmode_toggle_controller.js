import { Controller } from "@hotwired/stimulus"

// Handles sortmode toggle button
// Replaces inline onmousedown handler
export default class extends Controller {
  toggle(event) {
    // Delegate to existing SortmodeToggle.click for backwards compatibility
    if (typeof SortmodeToggle !== "undefined" && SortmodeToggle.click) {
      SortmodeToggle.click.call(this.element, event)
    }
  }
}
