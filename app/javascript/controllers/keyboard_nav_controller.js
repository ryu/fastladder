import { Controller } from "@hotwired/stimulus"

// Keyboard navigation controller for mobile feed reader
// Supports j/k navigation, p (pin), v (view), s (next action)
//
// Usage:
//   <div data-controller="keyboard-nav" data-keyboard-nav-initial-value="item-123">
//     <div data-keyboard-nav-target="item" id="item-1">...</div>
//     <div data-keyboard-nav-target="item" id="item-2">...</div>
//     <a data-keyboard-nav-target="next" href="...">Next</a>
//   </div>
export default class extends Controller {
  static targets = ["item", "next"]
  static values = {
    initial: { type: String, default: "" },
    highlightColor: { type: String, default: "#ffffcc" },
    defaultColor: { type: String, default: "#f9f9f9" }
  }

  connect() {
    this.currentId = this.initialValue || this.itemTargets[0]?.id || ""

    // Handle hash navigation
    if (window.location.hash) {
      this.currentId = window.location.hash.replace("#", "")
    }

    if (this.currentId) {
      this.scrollToCurrent()
    }

    // Bind keyboard events
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.boundHandleKeyup = this.handleKeyup.bind(this)
    window.addEventListener("keydown", this.boundHandleKeydown)
    window.addEventListener("keyup", this.boundHandleKeyup)
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundHandleKeydown)
    window.removeEventListener("keyup", this.boundHandleKeyup)
  }

  handleKeydown(event) {
    // Don't handle if user is typing in an input
    if (this.isTyping(event)) return

    const ids = this.itemTargets.map(item => item.id)
    const currentIndex = ids.indexOf(this.currentId)

    if (event.key === "j") {
      // Next item
      const nextId = ids[currentIndex + 1]
      if (nextId) {
        this.currentId = nextId
        this.scrollToCurrent()
      }
    } else if (event.key === "k") {
      // Previous item
      const prevId = ids[currentIndex - 1]
      if (prevId) {
        this.currentId = prevId
        this.scrollToCurrent()
      }
    }
  }

  handleKeyup(event) {
    // Don't handle if user is typing in an input
    if (this.isTyping(event)) return

    const currentItem = this.currentElement

    if (event.key === "p") {
      // Pin current item
      const pinLink = currentItem?.querySelector("a.pin, [data-action='pin']")
      if (pinLink) pinLink.click()
    } else if (event.key === "v") {
      // View/read current item
      const readLink = currentItem?.querySelector("a.read, [data-action='read']")
      if (readLink) readLink.click()
    } else if (event.key === "s") {
      // Next action (mark as read)
      if (this.hasNextTarget) {
        this.nextTarget.click()
      }
    }
  }

  scrollToCurrent() {
    // Reset all item backgrounds
    this.itemTargets.forEach(item => {
      item.style.backgroundColor = this.defaultColorValue
    })

    // Highlight and scroll to current
    const current = this.currentElement
    if (current) {
      current.scrollIntoView({ behavior: "smooth", block: "start" })
      current.style.backgroundColor = this.highlightColorValue
    }
  }

  get currentElement() {
    return document.getElementById(this.currentId)
  }

  isTyping(event) {
    const target = event.target
    return target.tagName === "INPUT" ||
           target.tagName === "TEXTAREA" ||
           target.isContentEditable
  }
}
