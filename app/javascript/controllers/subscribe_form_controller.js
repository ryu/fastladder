import { Controller } from "@hotwired/stimulus"

// Handles subscribe form show/hide toggle
// Replaces inline onclick="Control.show_subscribe_form()" and onclick="Control.hide_subscribe_form()"
export default class extends Controller {
  show() {
    // Delegate to existing Control.show_subscribe_form for backwards compatibility
    if (typeof Control !== "undefined" && Control.show_subscribe_form) {
      Control.show_subscribe_form()
    }
  }

  hide() {
    // Delegate to existing Control.hide_subscribe_form for backwards compatibility
    if (typeof Control !== "undefined" && Control.hide_subscribe_form) {
      Control.hide_subscribe_form()
    }
  }
}
