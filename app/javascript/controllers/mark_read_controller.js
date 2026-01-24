import { Controller } from "@hotwired/stimulus"

// Mark as read controller for mobile feed reading.
//
// Usage:
//   <a href="/mobile/123/read?timestamp=..."
//      data-controller="mark-read"
//      data-action="click->mark-read#submit">Mark as read</a>
//
export default class extends Controller {
  async submit(event) {
    event.preventDefault()
    const link = event.currentTarget
    const button = link.querySelector("button") || link
    const originalText = button.textContent
    const url = link.href

    button.textContent = "Marking..."
    button.disabled = true
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
        button.textContent = "Done! Redirecting..."
        // Redirect to mobile index after short delay
        setTimeout(() => {
          window.location.href = data.redirect_to || "/mobile"
        }, 500)
      } else {
        button.textContent = "Error - tap to retry"
        button.disabled = false
        link.style.pointerEvents = ""
      }
    } catch (error) {
      button.textContent = originalText
      button.disabled = false
      link.style.pointerEvents = ""
    }
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
