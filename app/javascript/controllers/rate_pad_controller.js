import { Controller } from "@hotwired/stimulus"

// Handles rate pad interactions (star rating)
// Replaces inline onclick/onmouseout/onmousemove handlers
export default class extends Controller {
  click(event) {
    // Delegate to existing LDR.Rate.click for backwards compatibility
    if (typeof LDR !== "undefined" && LDR.Rate && LDR.Rate.click) {
      LDR.Rate.click.call(this.element, event)
    }
  }

  out(event) {
    // Delegate to existing LDR.Rate.out for backwards compatibility
    if (typeof LDR !== "undefined" && LDR.Rate && LDR.Rate.out) {
      LDR.Rate.out.call(this.element, event)
    }
  }

  hover(event) {
    // Delegate to existing LDR.Rate.hover for backwards compatibility
    if (typeof LDR !== "undefined" && LDR.Rate && LDR.Rate.hover) {
      LDR.Rate.hover.call(this.element, event)
    }
  }
}
