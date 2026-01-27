import { Controller } from "@hotwired/stimulus"

// Handles clip rate pad interactions (bookmark rating)
// Replaces inline onclick/onmouseout/onmousemove handlers
export default class extends Controller {
  click(event) {
    // Delegate to existing ClipRate.click for backwards compatibility
    if (typeof ClipRate !== "undefined" && ClipRate.click) {
      ClipRate.click.call(this.element, event)
    }
  }

  out(event) {
    // Delegate to existing ClipRate.out for backwards compatibility
    if (typeof ClipRate !== "undefined" && ClipRate.out) {
      ClipRate.out.call(this.element, event)
    }
  }

  hover(event) {
    // Delegate to existing ClipRate.hover for backwards compatibility
    if (typeof ClipRate !== "undefined" && ClipRate.hover) {
      ClipRate.hover.call(this.element, event)
    }
  }
}
