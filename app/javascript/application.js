// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

// IMPORTANT: Import Stimulus FIRST before any controllers
import { Application } from "@hotwired/stimulus"
const application = Application.start()
application.debug = false
window.Stimulus = application

// Now import Turbo
import "@hotwired/turbo-rails"

// IMPORTANT: Disable Turbo Drive globally to prevent conflicts with existing LDR JavaScript.
Turbo.session.drive = false

// Finally import controllers (they depend on Stimulus being ready)
import "controllers"
