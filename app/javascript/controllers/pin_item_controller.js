import { Controller } from "@hotwired/stimulus"

// Pin Item controller - handles pin item interactions in dropdown
//
// This controller manages pin items in the pin dropdown menu,
// bridging to legacy PinItem and Control functions.
//
// Usage:
//   <span data-controller="pin-item"
//         data-pin-item-link-value="http://example.com"
//         data-action="mouseout->pin-item#unhover mouseover->pin-item#hover mouseup->pin-item#select">
//     Article Title
//   </span>
//
export default class extends Controller {
  static values = {
    link: String
  }

  hover() {
    this.element.classList.add("hover")
    // Call legacy PinItem if available
    if (typeof PinItem !== "undefined" && PinItem.onhover) {
      PinItem.onhover.call(this.element, event)
    }
  }

  unhover() {
    this.element.classList.remove("hover")
    if (typeof PinItem !== "undefined" && PinItem.onunhover) {
      PinItem.onunhover.call(this.element, event)
    }
  }

  select() {
    const link = this.linkValue

    // Use legacy Control.read_pin if available
    if (typeof Control !== "undefined" && Control.read_pin) {
      Control.read_pin(link)
    } else {
      // Fallback: dispatch event for Hotwire handling
      this.dispatch("pinSelected", { detail: { link } })
    }

    // Hide menu after selection
    this.hideMenu()
  }

  hideMenu() {
    if (typeof FlatMenu !== "undefined" && FlatMenu.hideAll) {
      FlatMenu.hideAll()
    }
  }
}
