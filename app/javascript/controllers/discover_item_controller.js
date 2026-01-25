import { Controller } from "@hotwired/stimulus"

// Discover Item controller - handles feed subscription in discovery results
//
// This controller manages subscribe/unsubscribe actions in the feed
// discovery popup, bridging to legacy API functions.
//
// Usage:
//   <a data-controller="discover-item"
//      data-discover-item-feedlink-value="http://example.com/feed"
//      data-action="click->discover-item#subscribe">
//     Add
//   </a>
//
export default class extends Controller {
  static values = {
    feedlink: String
  }

  subscribe(event) {
    event.preventDefault()
    const feedlink = this.feedlinkValue

    // Use legacy API if available
    if (typeof LDR !== "undefined" && LDR.API && LDR.API.subscribe) {
      LDR.API.subscribe(feedlink)
    } else if (typeof subscribe_from_discover === "function") {
      subscribe_from_discover(feedlink)
    } else {
      // Fallback: use fetch API
      this.subscribeViaFetch(feedlink)
    }
  }

  unsubscribe(event) {
    event.preventDefault()
    const feedlink = this.feedlinkValue

    // Use legacy API if available
    if (typeof LDR !== "undefined" && LDR.API && LDR.API.unsubscribe) {
      LDR.API.unsubscribe(feedlink)
    } else if (typeof unsubscribe_from_discover === "function") {
      unsubscribe_from_discover(feedlink)
    } else {
      // Fallback: use fetch API
      this.unsubscribeViaFetch(feedlink)
    }
  }

  async subscribeViaFetch(feedlink) {
    try {
      const response = await fetch("/api/feed/subscribe", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": this.csrfToken
        },
        body: new URLSearchParams({ feedlink })
      })

      if (response.ok) {
        this.updateUI(true)
        this.dispatch("subscribed", { detail: { feedlink } })
      }
    } catch (error) {
      console.error("[DiscoverItem] Subscribe failed:", error)
    }
  }

  async unsubscribeViaFetch(feedlink) {
    try {
      const response = await fetch("/api/feed/unsubscribe", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": this.csrfToken
        },
        body: new URLSearchParams({ feedlink })
      })

      if (response.ok) {
        this.updateUI(false)
        this.dispatch("unsubscribed", { detail: { feedlink } })
      }
    } catch (error) {
      console.error("[DiscoverItem] Unsubscribe failed:", error)
    }
  }

  updateUI(subscribed) {
    const container = this.element.closest(".discover_item")
    if (!container) return

    const buttonContainer = container.querySelector("div[style*='float']")
    if (buttonContainer) {
      if (subscribed) {
        buttonContainer.classList.add("subscribed")
        this.element.textContent = "Unsubscribe"
        this.element.classList.remove("sub_button")
        this.element.classList.add("unsub_button")
        this.element.setAttribute("rel", "unsubscribe")
        // Update action
        this.element.dataset.action = "click->discover-item#unsubscribe"
      } else {
        buttonContainer.classList.remove("subscribed")
        this.element.textContent = "Add"
        this.element.classList.remove("unsub_button")
        this.element.classList.add("sub_button")
        this.element.setAttribute("rel", "subscribe")
        // Update action
        this.element.dataset.action = "click->discover-item#subscribe"
      }
    }

    // Update [Subscribed] label
    const subscribedLabel = container.querySelector("span[style*='color: red']")
    if (subscribed && !subscribedLabel) {
      const span = document.createElement("span")
      span.style.color = "red"
      span.textContent = "[Subscribed]"
      const usersSpan = container.querySelector("span[style*='#717578']")
      if (usersSpan) {
        usersSpan.insertAdjacentHTML("afterend", "&nbsp;<span style='color: red;'>[Subscribed]</span>")
      }
    } else if (!subscribed && subscribedLabel) {
      subscribedLabel.remove()
    }
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
