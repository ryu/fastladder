import { Controller } from "@hotwired/stimulus"

// Handles Escape key to close clip form
// Replaces inline onkeypress/onkeyup handlers
export default class extends Controller {
  static values = {
    itemId: Number
  }

  escape(event) {
    if (event.keyCode === 27) { // Escape key
      const itemId = this.itemIdValue
      // Delegate to existing clip_click for backwards compatibility
      if (typeof clip_click !== "undefined") {
        clip_click(itemId)
      }
    }
  }
}
