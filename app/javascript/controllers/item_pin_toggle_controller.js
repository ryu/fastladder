import { Controller } from "@hotwired/stimulus"

// Handles pin toggle on individual items
// Replaces inline onmousedown="toggle_pin([[id]])"
export default class extends Controller {
  static values = {
    itemId: Number
  }

  toggle(event) {
    const itemId = this.itemIdValue
    // Delegate to existing toggle_pin for backwards compatibility
    if (typeof toggle_pin !== "undefined") {
      toggle_pin(itemId)
    }
  }
}
