import { Controller } from "@hotwired/stimulus"

// Handles pin button interactions in the reader toolbar
// Replaces inline onmouseover/onmouseout/onclick handlers
export default class extends Controller {
  hover(event) {
    // Delegate to existing Control.pin_hover for backwards compatibility
    if (typeof Control !== "undefined" && Control.pin_hover) {
      Control.pin_hover.call(this.element, event)
    }
  }

  out(event) {
    // Delegate to existing Control.pin_mouseout for backwards compatibility
    if (typeof Control !== "undefined" && Control.pin_mouseout) {
      Control.pin_mouseout.call(this.element, event)
    }
  }

  click(event) {
    // Delegate to existing Control.pin_click for backwards compatibility
    if (typeof Control !== "undefined" && Control.pin_click) {
      Control.pin_click.call(this.element, event)
    }
  }
}
