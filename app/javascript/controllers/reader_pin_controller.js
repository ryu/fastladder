import { Controller } from "@hotwired/stimulus"

// Reader Pin controller - handles pin toggle in reader view
//
// This controller integrates with the legacy Pin model and turbo_bridge.js
// to provide a unified pin toggle experience.
//
// Usage:
//   <span data-controller="reader-pin"
//         data-reader-pin-item-id-value="123"
//         data-reader-pin-link-value="http://example.com/article"
//         data-reader-pin-title-value="Article Title">
//     <img data-action="mousedown->reader-pin#toggle" src="/img/icon/pin.gif">
//   </span>
//
export default class extends Controller {
  static values = {
    itemId: Number,
    link: String,
    title: String,
    pinned: { type: Boolean, default: false }
  }

  connect() {
    // Check if already pinned from legacy Pin model
    if (typeof Pin !== "undefined" && Pin.items) {
      this.pinnedValue = Pin.items.some(pin => pin.link === this.linkValue)
    }
    this.updateVisualState()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.pinnedValue) {
      this.remove()
    } else {
      this.add()
    }
  }

  async add() {
    // Update optimistically
    this.pinnedValue = true
    this.updateVisualState()

    try {
      // Use legacy Pin model if available (it handles the API call via turbo_bridge)
      if (typeof Pin !== "undefined" && typeof Pinsaver !== "undefined") {
        Pinsaver.add(this.linkValue, this.titleValue)
        // Legacy JS will handle the API call and Turbo Stream response
        this.dispatchPinEvent("ldr:pin-added", { link: this.linkValue, title: this.titleValue })
      } else {
        // Fallback: direct API call
        await this.callPinAPI("add")
      }
    } catch (error) {
      console.error("[ReaderPin] Add failed:", error)
      this.pinnedValue = false
      this.updateVisualState()
    }
  }

  async remove() {
    // Update optimistically
    this.pinnedValue = false
    this.updateVisualState()

    try {
      if (typeof Pin !== "undefined" && typeof Pinsaver !== "undefined") {
        Pinsaver.remove(this.linkValue)
        this.dispatchPinEvent("ldr:pin-removed", { link: this.linkValue })
      } else {
        await this.callPinAPI("remove")
      }
    } catch (error) {
      console.error("[ReaderPin] Remove failed:", error)
      this.pinnedValue = true
      this.updateVisualState()
    }
  }

  async callPinAPI(action) {
    const url = `/api/pin/${action}`
    const params = new URLSearchParams()
    params.append("link", this.linkValue)
    if (action === "add") {
      params.append("title", this.titleValue)
    }

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "text/vnd.turbo-stream.html, application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: params
    })

    if (!response.ok) {
      throw new Error(`API call failed: ${response.status}`)
    }

    // If Turbo Stream response, it will be handled automatically
    const contentType = response.headers.get("Content-Type") || ""
    if (contentType.includes("turbo-stream")) {
      // Turbo will handle DOM updates
      return
    }

    // JSON response - update manually
    const data = await response.json()
    if (!data.isSuccess) {
      throw new Error(`API error: ${data.ErrorCode}`)
    }
  }

  updateVisualState() {
    const pinElement = document.getElementById(`pin_${this.itemIdValue}`)
    if (pinElement) {
      if (this.pinnedValue) {
        pinElement.classList.add("pin_active")
        pinElement.classList.remove("pin_inactive")
      } else {
        pinElement.classList.remove("pin_active")
        pinElement.classList.add("pin_inactive")
      }
    }

    // Also update parent item styling
    const itemElement = document.getElementById(`item_${this.itemIdValue}`)
    if (itemElement) {
      if (this.pinnedValue) {
        itemElement.classList.add("pinned")
      } else {
        itemElement.classList.remove("pinned")
      }
    }
  }

  dispatchPinEvent(eventName, detail) {
    document.dispatchEvent(new CustomEvent(eventName, { detail }))
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
