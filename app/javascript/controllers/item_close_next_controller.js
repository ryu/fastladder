import { Controller } from "@hotwired/stimulus"

// Handles close and next item action
// Replaces inline onmousedown="Control.close_and_next_item([[id]],event)"
export default class extends Controller {
  static values = {
    itemId: Number
  }

  close(event) {
    const itemId = this.itemIdValue
    // Delegate to existing Control.close_and_next_item for backwards compatibility
    if (typeof Control !== "undefined" && Control.close_and_next_item) {
      Control.close_and_next_item(itemId, event)
    }
  }
}
