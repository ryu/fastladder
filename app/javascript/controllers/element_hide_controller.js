import { Controller } from "@hotwired/stimulus"

// Generic controller to hide elements by ID
// Replaces inline onclick="Element.hide('...')" or onmousedown="DOM.hide('...')"
export default class extends Controller {
  static values = {
    target: String
  }

  hide() {
    const targetId = this.targetValue
    if (!targetId) return

    const element = document.getElementById(targetId)
    if (element) {
      element.style.display = "none"
    }
  }
}
