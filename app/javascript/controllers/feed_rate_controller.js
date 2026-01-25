import { Controller } from "@hotwired/stimulus"

// Feed Rate controller - handles feed rating
//
// This controller manages the rating widget for feeds,
// bridging to legacy LDR.Rate functions.
//
// Usage:
//   <img data-controller="feed-rate"
//        data-feed-rate-subscribe-id-value="123"
//        data-action="click->feed-rate#click mouseout->feed-rate#out mousemove->feed-rate#hover">
//
export default class extends Controller {
  static values = {
    subscribeId: Number
  }

  click(event) {
    // Use legacy function if available
    if (typeof LDR !== "undefined" && LDR.Rate && LDR.Rate.click) {
      LDR.Rate.click.call(this.element, event)
    } else {
      this.handleClick(event)
    }
  }

  out(event) {
    if (typeof LDR !== "undefined" && LDR.Rate && LDR.Rate.out) {
      LDR.Rate.out.call(this.element, event)
    }
  }

  hover(event) {
    if (typeof LDR !== "undefined" && LDR.Rate && LDR.Rate.hover) {
      LDR.Rate.hover.call(this.element, event)
    }
  }

  handleClick(event) {
    // Calculate rate from mouse position
    const rect = this.element.getBoundingClientRect()
    const x = event.clientX - rect.left
    const rate = Math.ceil(x / (rect.width / 5))

    this.setRate(rate)
  }

  async setRate(rate) {
    const subscribeId = this.subscribeIdValue

    try {
      const response = await fetch(`/api/subs/${subscribeId}/rate`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html, application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ rate })
      })

      if (response.ok) {
        // Update UI
        this.element.src = `/img/rate/pad/${rate}.gif`
        this.dispatch("rated", { detail: { subscribeId, rate } })
      }
    } catch (error) {
      console.error("[FeedRate] Failed to set rate:", error)
    }
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
