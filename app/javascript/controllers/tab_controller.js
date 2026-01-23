import { Controller } from "@hotwired/stimulus"

// Tab switching controller
// Usage:
//   <div data-controller="tab">
//     <button data-tab-target="tab" data-action="click->tab#switch" data-tab-mode="all">All</button>
//     <button data-tab-target="tab" data-action="click->tab#switch" data-tab-mode="active">Active</button>
//     <div data-tab-target="content" data-tab-mode="all">Content for all</div>
//     <div data-tab-target="content" data-tab-mode="active">Content for active</div>
//   </div>
//
// For CSS class-based visibility (e.g., .show-subscribed .subscribed { display: block }):
//   <div data-controller="tab" data-tab-css-mode-value="true">
//     ...
//   </div>
export default class extends Controller {
  static targets = ["tab", "content"]
  static values = {
    activeClass: { type: String, default: "tab-active" },
    cssMode: { type: Boolean, default: false }
  }

  connect() {
    // Activate first tab by default if none is active
    const activeTab = this.tabTargets.find(tab => tab.classList.contains(this.activeClassValue))
    if (!activeTab && this.tabTargets.length > 0) {
      this.activateTab(this.tabTargets[0])
    }
  }

  switch(event) {
    event.preventDefault()
    this.activateTab(event.currentTarget)
  }

  activateTab(selectedTab) {
    const mode = selectedTab.dataset.tabMode

    // Update tab styles
    this.tabTargets.forEach(tab => {
      if (tab === selectedTab) {
        tab.classList.add(this.activeClassValue)
      } else {
        tab.classList.remove(this.activeClassValue)
      }
    })

    // CSS class-based visibility (show-* pattern)
    // Remove all show-* classes and add the current one
    this.element.className = this.element.className.replace(/show-\S+/g, "").trim()
    if (mode && mode !== "all") {
      this.element.classList.add(`show-${mode}`)
    }

    // Also handle content targets with inline style display
    if (this.hasContentTarget) {
      this.contentTargets.forEach(content => {
        const contentMode = content.dataset.tabMode
        const shouldShow = !mode || contentMode === mode || mode === "all"
        content.style.display = shouldShow ? "" : "none"
      })
    }
  }
}
