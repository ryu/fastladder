import { Controller } from "@hotwired/stimulus"

// Checkbox group controller for select all / none functionality
// Usage:
//   <div data-controller="checkbox-group">
//     <button data-action="click->checkbox-group#selectAll">Select All</button>
//     <button data-action="click->checkbox-group#selectNone">None</button>
//     <input type="checkbox" data-checkbox-group-target="checkbox">
//     <input type="checkbox" data-checkbox-group-target="checkbox">
//   </div>
export default class extends Controller {
  static targets = ["checkbox"]

  selectAll(event) {
    if (event) event.preventDefault()
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
  }

  selectNone(event) {
    if (event) event.preventDefault()
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
  }

  toggle(event) {
    if (event) event.preventDefault()
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = !checkbox.checked
    })
  }
}
