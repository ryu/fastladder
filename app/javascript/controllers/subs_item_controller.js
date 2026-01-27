import { Controller } from "@hotwired/stimulus"

// Handles subscription item hover interactions in sidebar
// Replaces inline onmouseover/onmouseout handlers in subscribe_item template
export default class extends Controller {
  hover(event) {
    // Delegate to existing SubsItem.onhover for backwards compatibility
    if (typeof SubsItem !== "undefined" && SubsItem.onhover) {
      SubsItem.onhover.call(this.element, event)
    }
  }

  unhover(event) {
    // Delegate to existing SubsItem.onunhover for backwards compatibility
    if (typeof SubsItem !== "undefined" && SubsItem.onunhover) {
      SubsItem.onunhover.call(this.element, event)
    }
  }
}
