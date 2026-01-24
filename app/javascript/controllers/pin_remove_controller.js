import { Controller } from "@hotwired/stimulus"

// Pin remove controller for removing pins from the pins list.
//
// Usage:
//   <li id="pin-123"
//       data-controller="pin-remove"
//       data-pin-remove-id-value="123">
//     <a href="#" data-action="click->pin-remove#remove">Remove</a>
//   </li>
//
export default class extends Controller {
  static values = { id: Number }

  async remove(event) {
    event.preventDefault()
    const link = event.currentTarget
    const originalText = link.textContent

    link.textContent = "Removing..."
    link.style.pointerEvents = "none"

    try {
      const response = await fetch(`/pins/${this.idValue}`, {
        method: "DELETE",
        headers: {
          "Accept": "text/vnd.turbo-stream.html, application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      if (response.ok) {
        const contentType = response.headers.get("content-type") || ""
        if (contentType.includes("turbo-stream")) {
          // Turbo handles DOM removal automatically
          return
        }
        // JSON fallback
        const data = await response.json()
        if (data.success) {
          this.element.remove()
        } else {
          this.resetLink(link, originalText)
        }
      } else {
        this.resetLink(link, originalText)
      }
    } catch (error) {
      this.resetLink(link, originalText)
    }
  }

  resetLink(link, text) {
    link.textContent = text
    link.style.pointerEvents = ""
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
