import { Controller } from "@hotwired/stimulus"

// Item Close controller - handles closing items and moving to next
//
// This controller manages the close button on feed items,
// bridging to legacy Control.close_and_next_item.
//
// Usage:
//   <img data-controller="item-close"
//        data-item-close-id-value="123"
//        data-action="mousedown->item-close#closeAndNext">
//
export default class extends Controller {
  static values = {
    id: Number
  }

  closeAndNext(event) {
    event.preventDefault()
    event.stopPropagation()

    const itemId = this.idValue

    // Use legacy function if available
    if (typeof Control !== "undefined" && Control.close_and_next_item) {
      Control.close_and_next_item(itemId, event)
    } else {
      // Fallback: hide item and dispatch event
      this.closeItem(itemId)
      this.dispatch("closed", { detail: { id: itemId } })
    }
  }

  closeItem(itemId) {
    const itemElement = document.getElementById(`item_${itemId}`)
    if (itemElement) {
      itemElement.style.display = "none"
      itemElement.classList.add("closed")
    }
  }
}
