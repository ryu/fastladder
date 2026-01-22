import { Controller } from "@hotwired/stimulus"

// Validates that password and password confirmation fields match.
// Shows visual feedback and disables submit button when they don't match.
//
// Usage:
//   <form data-controller="password-match">
//     <input type="password" data-password-match-target="password" data-action="input->password-match#validate">
//     <input type="password" data-password-match-target="confirmation" data-action="input->password-match#validate">
//     <span data-password-match-target="message"></span>
//     <button type="submit" data-password-match-target="submit">Sign Up</button>
//   </form>
//
export default class extends Controller {
  static targets = ["password", "confirmation", "message", "submit"]

  connect() {
    // Initial validation on connect (in case of browser autofill)
    this.validate()
  }

  validate() {
    const password = this.passwordTarget.value
    const confirmation = this.confirmationTarget.value

    // Don't show any message if confirmation is empty
    if (confirmation === "") {
      this.clearMessage()
      this.enableSubmit()
      return
    }

    if (password === confirmation) {
      this.showMatch()
      this.enableSubmit()
    } else {
      this.showMismatch()
      this.disableSubmit()
    }
  }

  showMatch() {
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = "Passwords match"
      this.messageTarget.style.color = "green"
    }
  }

  showMismatch() {
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = "Passwords do not match"
      this.messageTarget.style.color = "red"
    }
  }

  clearMessage() {
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = ""
    }
  }

  enableSubmit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
    }
  }

  disableSubmit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
    }
  }
}
