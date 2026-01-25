import { Controller } from "@hotwired/stimulus"

// Reader page controller - coordinates between legacy LDR.js and Hotwire
//
// This controller acts as a bridge during the migration from legacy JS to Hotwire.
// It listens to Turbo Stream events and coordinates UI updates.
//
// Usage:
//   <body data-controller="reader">
//     ...existing reader content...
//   </body>
//
export default class extends Controller {
  static targets = ["pinCount", "loading", "message"]

  connect() {
    console.log("[Reader] Stimulus controller connected")

    // Listen for Turbo Stream events to update UI
    document.addEventListener("turbo:before-stream-render", this.beforeStreamRender.bind(this))
    document.addEventListener("turbo:after-stream-render", this.afterStreamRender.bind(this))

    // Listen for custom events from legacy JS
    document.addEventListener("ldr:pin-added", this.handlePinAdded.bind(this))
    document.addEventListener("ldr:pin-removed", this.handlePinRemoved.bind(this))
    document.addEventListener("ldr:feed-read", this.handleFeedRead.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.beforeStreamRender.bind(this))
    document.removeEventListener("turbo:after-stream-render", this.afterStreamRender.bind(this))
    document.removeEventListener("ldr:pin-added", this.handlePinAdded.bind(this))
    document.removeEventListener("ldr:pin-removed", this.handlePinRemoved.bind(this))
    document.removeEventListener("ldr:feed-read", this.handleFeedRead.bind(this))
  }

  // Turbo Stream event handlers
  beforeStreamRender(event) {
    // Log stream actions for debugging during migration
    const stream = event.target
    if (stream) {
      console.log("[Reader] Turbo Stream action:", stream.action, stream.target)
    }
  }

  afterStreamRender(event) {
    // After Turbo updates DOM, notify legacy JS if needed
    this.syncWithLegacyJS()
  }

  // Custom event handlers for legacy JS integration
  handlePinAdded(event) {
    this.updatePinCount()
  }

  handlePinRemoved(event) {
    this.updatePinCount()
  }

  handleFeedRead(event) {
    // Legacy JS marked a feed as read, update if needed
    const { subscriptionId } = event.detail || {}
    if (subscriptionId) {
      this.updateSubscriptionUnread(subscriptionId, 0)
    }
  }

  // UI update methods
  updatePinCount() {
    // Sync pin count between legacy JS and Turbo-updated elements
    const pinCountEl = document.getElementById("pin_count")
    if (pinCountEl && typeof Pin !== "undefined" && Pin.items) {
      pinCountEl.textContent = Pin.items.length > 0 ? Pin.items.length : ""
    }
  }

  updateSubscriptionUnread(subscriptionId, count) {
    // Update unread count in the sidebar
    const subsItem = document.getElementById(`subs_item_${subscriptionId}`)
    if (subsItem) {
      // Update the text content to reflect new count
      const text = subsItem.textContent
      subsItem.textContent = text.replace(/\(\d+\)/, `(${count})`)
    }
  }

  syncWithLegacyJS() {
    // Called after Turbo Stream updates to sync state with legacy JS
    // This helps during the transition period
    if (typeof app !== "undefined" && app.state) {
      // Refresh subscription list if available
      if (typeof Control !== "undefined" && Control.reload_subs) {
        // Don't auto-reload, just log for now
        console.log("[Reader] Turbo Stream update complete, legacy state may need refresh")
      }
    }
  }

  // Actions that can be called from HTML via data-action
  togglePin(event) {
    event.preventDefault()
    const button = event.currentTarget
    const itemId = button.dataset.itemId

    if (typeof toggle_pin === "function") {
      // Use existing legacy function during transition
      toggle_pin(itemId)
    } else {
      console.warn("[Reader] toggle_pin function not available")
    }
  }

  markAllRead(event) {
    event.preventDefault()
    const button = event.currentTarget
    const subscriptionId = button.dataset.subscriptionId

    if (typeof touch_all === "function") {
      touch_all(subscriptionId)
    } else if (typeof Control !== "undefined" && Control.touch_all) {
      Control.touch_all(subscriptionId)
    } else {
      console.warn("[Reader] touch_all function not available")
    }
  }

  // Keyboard shortcut support (can extend hotkey_controller)
  handleKeyboard(event) {
    // Don't handle if typing in an input
    if (this.isTyping(event)) return

    // Let legacy hotkey manager handle for now
    // This method is here for future migration
  }

  isTyping(event) {
    const target = event.target
    return target.tagName === "INPUT" ||
           target.tagName === "TEXTAREA" ||
           target.isContentEditable
  }

  // Helper to get CSRF token
  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
