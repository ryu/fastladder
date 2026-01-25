import { Controller } from "@hotwired/stimulus"

// Feed Nav controller - handles feed pagination (prev/next)
//
// This controller manages the feed navigation buttons,
// bridging to legacy Control.feed_page.
//
// Usage:
//   <span data-controller="feed-nav"
//         data-action="click->feed-nav#prev">&lt;</span>
//   <span data-controller="feed-nav"
//         data-action="click->feed-nav#next">&gt;</span>
//
export default class extends Controller {
  prev(event) {
    event.preventDefault()
    this.navigate(-1)
  }

  next(event) {
    event.preventDefault()
    this.navigate(1)
  }

  navigate(direction) {
    // Use legacy function if available
    if (typeof Control !== "undefined" && Control.feed_page) {
      Control.feed_page(direction)
    } else {
      // Dispatch event for Hotwire handling
      this.dispatch("navigate", { detail: { direction } })
    }
  }
}
