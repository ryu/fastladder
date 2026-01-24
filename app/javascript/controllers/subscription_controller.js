import { Controller } from "@hotwired/stimulus"

// Subscription controller for managing feed subscriptions.
//
// Usage:
//   <li id="subscription-123"
//       data-controller="subscription"
//       data-subscription-id-value="123">
//     <button data-action="click->subscription#delete">Delete</button>
//   </li>
//
export default class extends Controller {
  static values = { id: Number }

  async delete(event) {
    event.preventDefault()
    const button = event.currentTarget
    const originalText = button.textContent

    button.disabled = true
    button.textContent = "Deleting..."

    try {
      const response = await fetch("/api/feed/unsubscribe", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "text/vnd.turbo-stream.html, application/json"
        },
        body: `subscribe_id=${this.idValue}&ApiKey=${window.ApiKey}`
      })

      if (response.ok) {
        const contentType = response.headers.get("content-type") || ""
        if (contentType.includes("turbo-stream")) {
          // Turbo handles DOM removal automatically via turbo_stream.remove
          return
        }
        // JSON fallback - remove element manually
        const data = await response.json()
        if (data.isSuccess) {
          this.element.remove()
        } else {
          this.resetButton(button, originalText)
        }
      } else {
        this.resetButton(button, originalText)
      }
    } catch (error) {
      this.resetButton(button, originalText)
    }
  }

  resetButton(button, text) {
    button.disabled = false
    button.textContent = text
  }
}
