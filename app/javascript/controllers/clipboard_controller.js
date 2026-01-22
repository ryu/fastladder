import { Controller } from "@hotwired/stimulus"

// Clipboard controller for copying text to clipboard.
//
// Usage:
//   <div data-controller="clipboard">
//     <input type="text" data-clipboard-target="source" value="text to copy" readonly>
//     <button data-action="clipboard#copy" data-clipboard-success-text="Copied!">Copy</button>
//   </div>
//
export default class extends Controller {
  static targets = ["source"]

  copy(event) {
    const button = event.currentTarget
    const originalText = button.textContent
    const successText = button.dataset.clipboardSuccessText || "Copied!"

    // Get text to copy
    const text = this.sourceTarget.value || this.sourceTarget.textContent

    // Copy to clipboard
    navigator.clipboard.writeText(text).then(() => {
      // Show success feedback
      button.textContent = successText
      button.disabled = true

      // Reset button after 2 seconds
      setTimeout(() => {
        button.textContent = originalText
        button.disabled = false
      }, 2000)
    }).catch((err) => {
      // Fallback for older browsers
      this.fallbackCopy(text)
      button.textContent = successText
      setTimeout(() => {
        button.textContent = originalText
      }, 2000)
    })
  }

  // Fallback copy method for browsers without clipboard API
  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)
  }
}
