import { Controller } from "@hotwired/stimulus"

// Pin controller for adding items to pins.
//
// Usage:
//   <a href="/mobile/123/pin"
//      data-controller="pin"
//      data-action="click->pin#create">Pin</a>
//
export default class extends Controller {
  async create(event) {
    event.preventDefault()
    const link = event.currentTarget
    const originalText = link.textContent
    const url = link.href

    link.textContent = "Pinning..."
    link.style.pointerEvents = "none"

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      if (response.ok) {
        const data = await response.json()
        link.textContent = data.already_pinned ? "Already pinned" : "Pinned!"
        link.classList.add("pinned")
      } else {
        link.textContent = "Error"
        setTimeout(() => {
          link.textContent = originalText
          link.style.pointerEvents = ""
        }, 2000)
      }
    } catch (error) {
      link.textContent = originalText
      link.style.pointerEvents = ""
    }
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
