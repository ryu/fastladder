import { Controller } from "@hotwired/stimulus"

// Handles show all button interactions
// Replaces inline onclick/onmouseover/onmouseout handlers
export default class extends Controller {
  toggle(event) {
    // Delegate to existing Control.toggle_show_all for backwards compatibility
    if (typeof Control !== "undefined" && Control.toggle_show_all) {
      Control.toggle_show_all.call(this.element, event)
    }
    // Also trigger mouseover effect
    if (typeof show_all_mouseover !== "undefined") {
      show_all_mouseover.call(this.element, event)
    }
  }

  hover(event) {
    // Delegate to existing show_all_mouseover for backwards compatibility
    if (typeof show_all_mouseover !== "undefined") {
      show_all_mouseover.call(this.element, event)
    }
  }

  out(event) {
    // Delegate to existing show_all_mouseout for backwards compatibility
    if (typeof show_all_mouseout !== "undefined") {
      show_all_mouseout.call(this.element, event)
    }
  }
}
