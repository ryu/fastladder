import { Controller } from "@hotwired/stimulus"

// Feed Item controller - manages individual feed items in the reader
//
// This controller handles item-level interactions and state management,
// bridging to legacy item functions.
//
// Usage:
//   <div data-controller="feed-item"
//        data-feed-item-id-value="123">
//     ...item content...
//   </div>
//
export default class extends Controller {
  static values = {
    id: Number
  }

  connect() {
    // Item is now visible in the DOM
    this.dispatch("connected", { detail: { id: this.idValue } })
  }

  disconnect() {
    this.dispatch("disconnected", { detail: { id: this.idValue } })
  }

  // Mark this item as read
  markRead() {
    if (typeof touch === "function") {
      touch(this.idValue, "read")
    }
    this.element.classList.add("read")
  }

  // Toggle pin state
  togglePin() {
    if (typeof toggle_pin === "function") {
      toggle_pin(this.idValue)
    }
  }

  // Scroll to this item
  scrollTo() {
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  // Get item info for sharing/clipping
  getInfo() {
    return {
      id: this.idValue,
      title: this.element.querySelector(".item_title a")?.textContent,
      link: this.element.querySelector(".item_title a")?.href,
      body: this.element.querySelector(".item_body .body")?.innerHTML
    }
  }
}
