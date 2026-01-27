import { Controller } from "@hotwired/stimulus"

// Prevents form submission
// Replaces inline onsubmit="return false"
export default class extends Controller {
  prevent(event) {
    event.preventDefault()
    return false
  }
}
