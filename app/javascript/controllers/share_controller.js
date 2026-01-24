import { Controller } from "@hotwired/stimulus"

// Share controller for managing subscription sharing settings.
//
// Replaces lib/share/share.js with modern Stimulus patterns.
//
export default class extends Controller {
  static targets = [
    "results", "resultsCount", "publicCount", "privateCount",
    "showAll", "progress", "memberPublic",
    "filterFromAll", "filterFromPublic", "filterFromPrivate",
    "filterSubscriberMin", "filterSubscriberMax", "filterString",
    "filterRate", "filterFolder", "mspaceRate", "mspaceFolders"
  ]

  static values = {
    apiKey: String,
    limit: { type: Number, default: 20 }
  }

  connect() {
    this.subs = []
    this.filteredSubs = []
    this.subsIndex = {}
    this.offset = 0
    this.showAllMode = false
    this.isDragging = false
    this.dragSelectState = false

    this.loadSubs()
  }

  // API calls
  async loadSubs() {
    this.resultsTarget.innerHTML = '<div class="loading">Loading ...</div>'

    try {
      const response = await fetch("/api/lite_subs", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json"
        },
        body: `ApiKey=${this.apiKeyValue}`
      })

      const data = await response.json()
      this.subs = data

      // Build index and prepare data
      let publicCount = 0
      let privateCount = 0

      this.subs.forEach(sub => {
        this.subsIndex[`_${sub.subscribe_id}`] = sub
        sub.link_lc = sub.link.toLowerCase()
        sub.title_lc = sub.title.toLowerCase()
        sub.selected = false

        if (sub.public) {
          publicCount++
        } else {
          privateCount++
        }
      })

      this.publicCountTarget.textContent = `${publicCount} items`
      this.privateCountTarget.textContent = `${privateCount} items`

      this.setupMspace()
      this.search()
    } catch (error) {
      this.resultsTarget.innerHTML = '<div class="error">Failed to load subscriptions</div>'
    }
  }

  setupMspace() {
    // Count by rate
    const rateCount = {}
    const folderCount = {}

    this.subs.forEach(sub => {
      rateCount[sub.rate] = (rateCount[sub.rate] || 0) + 1
      const folder = sub.folder || ""
      folderCount[folder] = (folderCount[folder] || 0) + 1
    })

    // Build rate select
    const rateText = ["Not Rated", "1 star", "2 stars", "3 stars", "4 stars", "5 stars"]
    let rateHtml = "<select data-share-target='filterRate' data-action='change->share#search' multiple style='height:120px;width:100%'>"
    ;[5, 4, 3, 2, 1, 0].forEach(num => {
      if (rateCount[num]) {
        rateHtml += `<option value="${num}" selected>${rateText[num]} (${rateCount[num]})</option>`
      }
    })
    rateHtml += "</select>"
    this.mspaceRateTarget.innerHTML = rateHtml

    // Build folder select
    const folderNames = Object.keys(folderCount).sort((a, b) => folderCount[b] - folderCount[a])
    // Ensure empty (uncategorized) is first
    const emptyIdx = folderNames.indexOf("")
    if (emptyIdx > 0) {
      folderNames.splice(emptyIdx, 1)
      folderNames.unshift("")
    }

    let folderHtml = "<select data-share-target='filterFolder' data-action='change->share#search' multiple style='height:120px;width:100%'>"
    folderNames.forEach(name => {
      const displayName = name === "" ? "[ Uncategorized ]" : this.escapeHtml(name)
      const count = folderCount[name]
      folderHtml += `<option value="${this.escapeHtml(name)}" selected>${displayName} (${count})</option>`
    })
    folderHtml += "</select>"
    this.mspaceFoldersTarget.innerHTML = folderHtml
  }

  // Search and filter
  search() {
    this.showAllMode = false
    this.filteredSubs = this.subs.filter(sub => this.matchesFilter(sub))
    this.render()
  }

  matchesFilter(sub) {
    // Target filter
    if (!this.filterFromAllTarget.checked) {
      if (this.filterFromPublicTarget.checked && !sub.public) return false
      if (this.filterFromPrivateTarget.checked && sub.public) return false
    }

    // Subscriber count filter
    const minSubs = parseInt(this.filterSubscriberMinTarget.value, 10)
    const maxSubs = parseInt(this.filterSubscriberMaxTarget.value, 10)
    if (!isNaN(minSubs) && sub.subscribers_count < minSubs) return false
    if (!isNaN(maxSubs) && sub.subscribers_count > maxSubs) return false

    // Text filter
    const searchStr = this.filterStringTarget.value.toLowerCase()
    if (searchStr && !sub.title_lc.includes(searchStr) && !sub.link_lc.includes(searchStr)) {
      return false
    }

    // Rate filter
    if (this.hasFilterRateTarget) {
      const selectedRates = Array.from(this.filterRateTarget.selectedOptions).map(o => o.value)
      if (selectedRates.length < this.filterRateTarget.options.length) {
        if (!selectedRates.includes(String(sub.rate))) return false
      }
    }

    // Folder filter
    if (this.hasFilterFolderTarget) {
      const selectedFolders = Array.from(this.filterFolderTarget.selectedOptions).map(o => o.value)
      if (selectedFolders.length < this.filterFolderTarget.options.length) {
        const subFolder = sub.folder || ""
        if (!selectedFolders.includes(subFolder)) return false
      }
    }

    return true
  }

  render() {
    this.resultsCountTarget.textContent = `${this.filteredSubs.length} items`

    const headerHtml = `
      <table id="result" cellspacing="0" cellpadding="0">
      <tr><th width="80" nowrap>State</th>
      <th width="80%">Title</th>
      <th width="60" nowrap>Subscribers</th>
      <th width="80">Rate</th></tr>
    `

    const subsToShow = this.showAllMode
      ? this.filteredSubs
      : this.filteredSubs.slice(this.offset, this.offset + this.limitValue)

    const rowsHtml = subsToShow.map(sub => this.formatRow(sub)).join("")
    this.resultsTarget.innerHTML = headerHtml + rowsHtml + "</table>"

    // Show/hide "show all" link
    if (this.filteredSubs.length > this.limitValue && !this.showAllMode) {
      this.showAllTarget.textContent = `Show all (${this.filteredSubs.length} items)`
      this.showAllTarget.style.display = "block"
    } else {
      this.showAllTarget.style.display = "none"
    }
  }

  formatRow(sub) {
    const classes = []
    if (!sub.public) classes.push("secret")
    if (sub.selected) classes.push("selected")

    const checked = sub.selected ? "checked" : ""
    const publicText = sub.public ? "Public" : "Private"
    const subscribersText = sub.subscribers_count > 1
      ? `${sub.subscribers_count} people`
      : "just you"

    return `
      <tr class="${classes.join(" ")}" id="tr_${sub.subscribe_id}"
          data-action="mouseover->share#rowMouseOver mousedown->share#rowMouseDown"
          data-sub-id="${sub.subscribe_id}">
        <td width="80" nowrap class="check_cell">
          <div class="check">
            <input type="checkbox" id="check_${sub.subscribe_id}" ${checked} onclick="return false">
            ${publicText}
          </div>
        </td>
        <td width="80%" style="background-image:url('${sub.icon}')" class="title_cell">
          ${this.escapeHtml(sub.title)}
        </td>
        <td width="60" nowrap>${subscribersText}</td>
        <td width="80" nowrap><img src="/img/rate/${sub.rate}.gif"></td>
      </tr>
    `
  }

  // Selection
  rowMouseDown(event) {
    event.preventDefault()
    this.isDragging = true
    const id = event.currentTarget.dataset.subId
    this.dragSelectState = this.toggleSelection(id)

    // Add mouseup listener to stop dragging
    document.addEventListener("mouseup", this.stopDragging.bind(this), { once: true })
  }

  rowMouseOver(event) {
    if (!this.isDragging) return
    const id = event.currentTarget.dataset.subId
    this.setSelection(id, this.dragSelectState)
  }

  stopDragging() {
    this.isDragging = false
  }

  toggleSelection(id) {
    const sub = this.subsIndex[`_${id}`]
    if (!sub) return false

    sub.selected = !sub.selected
    this.updateRowSelection(id, sub.selected)
    return sub.selected
  }

  setSelection(id, selected) {
    const sub = this.subsIndex[`_${id}`]
    if (!sub) return

    sub.selected = selected
    this.updateRowSelection(id, selected)
  }

  updateRowSelection(id, selected) {
    const checkbox = document.getElementById(`check_${id}`)
    const row = document.getElementById(`tr_${id}`)
    if (checkbox) checkbox.checked = selected
    if (row) {
      if (selected) {
        row.classList.add("selected")
      } else {
        row.classList.remove("selected")
      }
    }
  }

  selectAll() {
    const firstNotSelected = this.filteredSubs.length > 0 && !this.filteredSubs[0].selected
    this.filteredSubs.forEach(sub => {
      sub.selected = firstNotSelected
    })
    this.render()
  }

  // Actions
  setQuery(event) {
    const params = JSON.parse(event.currentTarget.dataset.query)
    if (params.subscriber_min !== undefined) {
      this.filterSubscriberMinTarget.value = params.subscriber_min
    }
    if (params.subscriber_max !== undefined) {
      this.filterSubscriberMaxTarget.value = params.subscriber_max
    }
    this.search()
  }

  resetMspace(event) {
    const type = event.currentTarget.dataset.mspaceType
    const select = type === "folder" ? this.filterFolderTarget : this.filterRateTarget
    Array.from(select.options).forEach(opt => { opt.selected = true })
    this.search()
  }

  showAll() {
    if (this.filteredSubs.length > 500) {
      if (!confirm("It might take a while due to the large number of entries.\nAre you sure to proceed?")) {
        return
      }
    }
    this.showAllMode = true
    this.render()
  }

  async setMemberPublic(event) {
    const value = event.currentTarget.dataset.publicValue

    try {
      await fetch("/api/config/save", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: `ApiKey=${this.apiKeyValue}&member_public=${value}`
      })

      // Reload page to reflect changes
      window.location.reload()
    } catch (error) {
      alert("Failed to update sharing settings")
    }
  }

  async setPublic(event) {
    const flag = parseInt(event.currentTarget.dataset.publicValue, 10)
    const selected = this.subs.filter(sub => sub.selected && sub.public !== Boolean(flag))

    if (selected.length === 0) {
      alert("No feeds selected or all selected feeds already have the target state.")
      return
    }

    const text = flag ? "Public" : "Private"
    if (!confirm(`Are you sure to mark ${selected.length} feeds as "${text}"?`)) {
      return
    }

    const subscribeIds = selected.map(sub => sub.subscribe_id).join(",")

    this.progressTarget.style.display = "inline"
    this.progressTarget.textContent = "Now saving"

    try {
      await fetch("/api/feed/set_public", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: `ApiKey=${this.apiKeyValue}&subscribe_id=${subscribeIds}&public=${flag}`
      })

      // Update local state
      selected.forEach(sub => {
        sub.public = Boolean(flag)
      })

      // Clear selections
      this.subs.forEach(sub => {
        sub.selected = false
      })

      // Update counts
      let publicCount = 0
      let privateCount = 0
      this.subs.forEach(sub => {
        if (sub.public) publicCount++
        else privateCount++
      })
      this.publicCountTarget.textContent = `${publicCount} items`
      this.privateCountTarget.textContent = `${privateCount} items`

      this.render()
    } catch (error) {
      alert("Failed to update feeds")
    } finally {
      this.progressTarget.textContent = ""
      this.progressTarget.style.display = "none"
    }
  }

  // Debounced search for text inputs
  searchDebounced() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => this.search(), 300)
  }

  // Utilities
  escapeHtml(str) {
    if (!str) return ""
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
