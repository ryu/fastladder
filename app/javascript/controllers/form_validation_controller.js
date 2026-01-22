import { Controller } from "@hotwired/stimulus"

// Form validation controller with inline error messages and loading state.
//
// Usage:
//   <form data-controller="form-validation">
//     <input data-form-validation-target="field" data-required="true" data-field-name="Username">
//     <span data-form-validation-target="error" data-for="username"></span>
//     <button data-form-validation-target="submit" data-loading-text="Signing in...">Sign In</button>
//   </form>
//
export default class extends Controller {
  static targets = ["field", "error", "submit"]

  connect() {
    this.originalSubmitText = this.hasSubmitTarget ? this.submitTarget.value : null
  }

  validate(event) {
    this.clearErrors()
    let isValid = true

    this.fieldTargets.forEach((field) => {
      if (field.dataset.required === "true" && !field.value.trim()) {
        isValid = false
        this.showError(field, `${field.dataset.fieldName || "This field"} is required`)
      }
    })

    if (!isValid) {
      event.preventDefault()
      // Focus first invalid field
      const firstInvalid = this.fieldTargets.find(
        (f) => f.dataset.required === "true" && !f.value.trim()
      )
      if (firstInvalid) firstInvalid.focus()
    } else {
      this.showLoading()
    }
  }

  showError(field, message) {
    // Find error element for this field
    const fieldId = field.id || field.name
    const errorEl = this.errorTargets.find((e) => e.dataset.for === fieldId)

    if (errorEl) {
      errorEl.textContent = message
      errorEl.style.color = "red"
      errorEl.style.fontSize = "0.9em"
      errorEl.style.display = "block"
    }

    // Add visual indicator to field
    field.style.borderColor = "red"
  }

  clearErrors() {
    this.errorTargets.forEach((errorEl) => {
      errorEl.textContent = ""
      errorEl.style.display = "none"
    })

    this.fieldTargets.forEach((field) => {
      field.style.borderColor = ""
    })
  }

  showLoading() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      if (this.submitTarget.dataset.loadingText) {
        this.submitTarget.value = this.submitTarget.dataset.loadingText
      }
    }
  }

  // Called when navigating away or on turbo:before-cache
  resetForm() {
    this.clearErrors()
    if (this.hasSubmitTarget && this.originalSubmitText) {
      this.submitTarget.disabled = false
      this.submitTarget.value = this.originalSubmitText
    }
  }
}
