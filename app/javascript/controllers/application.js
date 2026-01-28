import { Application } from "@hotwired/stimulus"

// This file is kept for backwards compatibility with controllers that import from it
// The actual Application is started in controllers/index.js

let application
if (window.Stimulus) {
  application = window.Stimulus
} else {
  application = Application.start()
  application.debug = false
  window.Stimulus = application
}

export { application }
