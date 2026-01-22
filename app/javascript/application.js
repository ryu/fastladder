// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// IMPORTANT: Disable Turbo Drive globally to prevent conflicts with existing LDR JavaScript.
// This allows us to opt-in to Turbo on specific pages/elements using data-turbo="true".
// Once migration is complete, this can be removed.
Turbo.session.drive = false
