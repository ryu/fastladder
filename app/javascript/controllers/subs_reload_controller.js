import { Controller } from "@hotwired/stimulus"

// Handles subscription list reload
// Replaces inline onclick="Control.reload_subs()"
export default class extends Controller {
  reload() {
    // Delegate to existing Control.reload_subs for backwards compatibility
    if (typeof Control !== "undefined" && Control.reload_subs) {
      Control.reload_subs()
    }
  }
}
