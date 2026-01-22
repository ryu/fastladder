import { Controller } from "@hotwired/stimulus"

// Auto-dismissing flash message controller.
// Automatically hides flash messages after a configurable delay.
// Also provides a close button for manual dismissal.
//
// Usage:
//   <div data-controller="flash" data-flash-delay-value="5000">
//     <p>Flash message content</p>
//     <button data-action="flash#close">×</button>
//   </div>
//
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 }
  }

  connect() {
    // Start auto-dismiss timer
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.delayValue)
  }

  disconnect() {
    // Clean up timer if element is removed
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  close() {
    // Manual close via button
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.dismiss()
  }

  dismiss() {
    // Fade out animation
    this.element.style.transition = "opacity 0.3s ease-out"
    this.element.style.opacity = "0"

    // Remove element after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
