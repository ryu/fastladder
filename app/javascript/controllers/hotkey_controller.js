import { Controller } from "@hotwired/stimulus"

// Simple hotkey controller for triggering clicks on elements
//
// Usage:
//   <div data-controller="hotkey">
//     <a href="..." data-hotkey-target="trigger" data-hotkey-key="s">First link</a>
//   </div>
//
// Or with a single key for the whole controller:
//   <div data-controller="hotkey" data-hotkey-key-value="s">
//     <a href="..." data-hotkey-target="trigger">First link</a>
//   </div>
export default class extends Controller {
  static targets = ["trigger"]
  static values = {
    key: { type: String, default: "" }
  }

  connect() {
    this.boundHandleKeyup = this.handleKeyup.bind(this)
    window.addEventListener("keyup", this.boundHandleKeyup)
  }

  disconnect() {
    window.removeEventListener("keyup", this.boundHandleKeyup)
  }

  handleKeyup(event) {
    // Don't handle if user is typing in an input
    if (this.isTyping(event)) return

    // Check if pressed key matches any trigger
    this.triggerTargets.forEach(trigger => {
      const triggerKey = trigger.dataset.hotkeyKey || this.keyValue
      if (triggerKey && event.key === triggerKey) {
        trigger.click()
      }
    })
  }

  isTyping(event) {
    const target = event.target
    return target.tagName === "INPUT" ||
           target.tagName === "TEXTAREA" ||
           target.isContentEditable
  }
}
