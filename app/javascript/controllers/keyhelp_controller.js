import { Controller } from "@hotwired/stimulus"

// Handles keyboard help panel toggle
// Replaces inline onclick="Control.toggle_keyhelp()"
export default class extends Controller {
  toggle() {
    // Delegate to existing Control.toggle_keyhelp for backwards compatibility
    if (typeof Control !== "undefined" && Control.toggle_keyhelp) {
      Control.toggle_keyhelp()
    }
  }
}
