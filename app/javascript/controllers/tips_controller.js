import { Controller } from "@hotwired/stimulus"

// Handles tips/loading click
// Replaces inline onclick="show_tips()"
export default class extends Controller {
  show() {
    // Delegate to existing show_tips for backwards compatibility
    if (typeof show_tips !== "undefined") {
      show_tips()
    }
  }
}
