import { Controller } from "@hotwired/stimulus"

// Handles manage mode initialization
// Replaces inline onclick="init_manage()"
export default class extends Controller {
  init() {
    // Delegate to existing init_manage for backwards compatibility
    if (typeof init_manage !== "undefined") {
      init_manage()
    }
  }
}
