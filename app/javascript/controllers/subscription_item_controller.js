import { Controller } from "@hotwired/stimulus"

// Subscription Item controller - handles subscription list items
//
// This controller manages subscription items in the sidebar,
// bridging to legacy SubsItem and Control functions.
//
// Usage:
//   <span data-controller="subscription-item"
//         data-subscription-item-id-value="123"
//         data-action="mouseover->subscription-item#hover mouseout->subscription-item#unhover click->subscription-item#select">
//     Feed Title (5)
//   </span>
//
export default class extends Controller {
  static values = {
    id: Number
  }

  hover() {
    this.element.classList.add("focus")
    // Call legacy SubsItem if available
    if (typeof SubsItem !== "undefined" && SubsItem.onhover) {
      SubsItem.onhover.call(this.element, event)
    }
  }

  unhover() {
    this.element.classList.remove("focus")
    if (typeof SubsItem !== "undefined" && SubsItem.onunhover) {
      SubsItem.onunhover.call(this.element, event)
    }
  }

  select(event) {
    event.preventDefault()
    const subscriptionId = this.idValue

    // Use legacy Control.read if available
    if (typeof Control !== "undefined" && Control.read) {
      Control.read(subscriptionId)
    } else {
      // Fallback: dispatch event for Hotwire handling
      this.dispatch("subscriptionSelected", { detail: { subscriptionId } })
      document.dispatchEvent(new CustomEvent("ldr:subscription-selected", {
        detail: { subscriptionId }
      }))
    }
  }

  // Update the unread count display
  updateCount(count) {
    const text = this.element.textContent || ""
    const newText = text.replace(/\(\d+\)/, `(${count})`)
    if (newText !== text) {
      this.element.textContent = newText
    }

    // Update CSS class based on count
    if (count === 0) {
      this.element.classList.remove("has_unread")
      this.element.classList.add("no_unread")
    } else {
      this.element.classList.add("has_unread")
      this.element.classList.remove("no_unread")
    }
  }
}
