import { Controller } from "@hotwired/stimulus"

// Subscription List controller for Reader page sidebar
//
// This controller manages the subscription list in the Reader sidebar,
// handling Turbo Stream updates for unread counts and integrating with
// the legacy subscription management code.
//
// Usage:
//   <div id="subs_body" data-controller="subscription-list">
//     <!-- subscription items rendered here -->
//   </div>
//
export default class extends Controller {
  static targets = ["item", "totalCount"]
  static values = {
    showUnreadOnly: { type: Boolean, default: false }
  }

  connect() {
    console.log("[SubscriptionList] Controller connected")

    // Listen for custom events from Turbo Stream updates
    document.addEventListener("turbo:after-stream-render", this.handleStreamUpdate.bind(this))

    // Listen for legacy JS events
    document.addEventListener("ldr:feed-read", this.handleFeedRead.bind(this))
    document.addEventListener("ldr:subscription-changed", this.handleSubscriptionChanged.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:after-stream-render", this.handleStreamUpdate.bind(this))
    document.removeEventListener("ldr:feed-read", this.handleFeedRead.bind(this))
    document.removeEventListener("ldr:subscription-changed", this.handleSubscriptionChanged.bind(this))
  }

  handleStreamUpdate(event) {
    // After Turbo updates the DOM, recalculate total unread count
    this.updateTotalCount()
  }

  handleFeedRead(event) {
    const { subscriptionId, unreadCount = 0 } = event.detail || {}
    if (subscriptionId) {
      this.updateItemCount(subscriptionId, unreadCount)
      this.updateTotalCount()
    }
  }

  handleSubscriptionChanged(event) {
    // Subscription was added or removed
    this.updateTotalCount()
  }

  updateItemCount(subscriptionId, count) {
    const itemEl = document.getElementById(`subs_item_${subscriptionId}`)
    if (!itemEl) return

    // Update the count in the item text
    const text = itemEl.textContent || ""
    const newText = text.replace(/\(\d+\)/, `(${count})`)
    if (newText !== text) {
      itemEl.textContent = newText
    }

    // Update item visibility based on show unread only mode
    if (this.showUnreadOnlyValue && count === 0) {
      itemEl.style.display = "none"
    } else {
      itemEl.style.display = ""
    }

    // Update item class
    if (count === 0) {
      itemEl.classList.remove("has_unread")
      itemEl.classList.add("no_unread")
    } else {
      itemEl.classList.add("has_unread")
      itemEl.classList.remove("no_unread")
    }
  }

  updateTotalCount() {
    // Calculate total unread from all visible items
    let total = 0
    const items = this.element.querySelectorAll("[subscribe_id]")

    items.forEach(item => {
      const match = item.textContent.match(/\((\d+)\)/)
      if (match) {
        total += parseInt(match[1], 10) || 0
      }
    })

    // Update total count display
    const totalEl = document.getElementById("total_unread_count")
    if (totalEl) {
      totalEl.textContent = total > 0 ? `${total} unread` : ""
    }

    // Also update legacy state if available
    if (typeof app !== "undefined" && app.state) {
      app.state.total_unread = total
    }

    console.log("[SubscriptionList] Total unread:", total)
  }

  // Actions
  toggleShowUnread(event) {
    this.showUnreadOnlyValue = !this.showUnreadOnlyValue
    this.refreshVisibility()
  }

  refreshVisibility() {
    const items = this.element.querySelectorAll("[subscribe_id]")

    items.forEach(item => {
      const match = item.textContent.match(/\((\d+)\)/)
      const count = match ? parseInt(match[1], 10) : 0

      if (this.showUnreadOnlyValue && count === 0) {
        item.style.display = "none"
      } else {
        item.style.display = ""
      }
    })
  }

  // Click handler for subscription items (for future use)
  selectItem(event) {
    const item = event.currentTarget
    const subscriptionId = item.getAttribute("subscribe_id")

    if (subscriptionId) {
      // Dispatch event for legacy JS to handle
      document.dispatchEvent(new CustomEvent("ldr:subscription-selected", {
        detail: { subscriptionId }
      }))

      // If legacy Control.read is available, use it
      if (typeof Control !== "undefined" && Control.read) {
        Control.read(subscriptionId)
      }
    }
  }
}
