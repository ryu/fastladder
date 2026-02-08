# Test Coverage Analysis - Prototype.js Removal Project

## Current Test Suite Overview

| Category | Files | Tests | Assertions |
|----------|-------|-------|------------|
| Model Tests | 5 | 55 | - |
| Controller Tests | 14 | 97 | - |
| System Tests | 8 | 11 | - |
| Routing Tests | - | 11 | - |
| Other (lib, request) | - | ~9 | - |
| **Total** | **~30** | **~258** | **~535** |

## System Tests (JavaScript-Related)

### Test Files and Coverage

| Test File | Tests | JS Interaction | Coverage Level |
|-----------|-------|---------------|----------------|
| `subscribe_crawl_read_test.rb` | 1 | **High** - click events, DOM assertions | Most comprehensive E2E |
| `config_test.rb` | 1 | **Medium** - tab click, form values | Config UI |
| `account_test.rb` | 2 | **Medium** - form interaction | Account management |
| `login_test.rb` | 2 | **Low** - form submit | Auth flow |
| `signup_stories_test.rb` | 2 | **Low** - form submit | Registration |
| `signin_stories_test.rb` | 1 | **Low** - form submit | Sign in |
| `signout_stories_test.rb` | 1 | **Low** - link click | Sign out |
| `subscribe_system_test.rb` | 1 | **Low** - form display | Subscribe form |

### JavaScript Features Verified by System Tests

```
subscribe_crawl_read_test.rb:
  ✅ Control.show_subscribe_form() - onclick handler
  ✅ Control.hide_subscribe_form() - onclick handler
  ✅ Subscribe button click (rel="subscribe")
  ✅ Feed item click (span[subscribe_id])
  ✅ "Loading completed." text assertion (async load)

config_test.rb:
  ✅ Tab switching (#tab_config_view click)
  ✅ Font size config value reading

account_test.rb:
  ✅ API key generation button
  ✅ Auth key display
```

## Coverage Gap Analysis

### CRITICAL GAPS (No Tests)

| Feature | JS Files Involved | Risk if Broken |
|---------|------------------|----------------|
| **Keyboard shortcuts** (j/k/p/v/o/s) | `hotkey_manager.js`, `commands.js` | High - core UX |
| **Pin UI operations** | `commands.js`, `models/pin.js` | High - data loss risk |
| **Mark as read UI** | `commands.js`, `reader/ajax.js` | High - core feature |
| **Folder UI operations** | `reader/folder.js`, `reader/main.js` | Medium - organizing |
| **Feed list rendering** | `reader/subscriber.js`, `ui/feed.js` | High - core display |
| **Article view rendering** | `ui/item.js`, `reader/view.js` | High - core display |
| **Mouse wheel scrolling** | `events/mouse_wheel.js` | Medium - navigation |
| **Drag and drop** | `reader/manage.js` | Low - optional |
| **Template rendering** | `lib/template.js` | High - all UI |

### COVERED (API Layer - No JS Verification)

| Feature | Controller Tests | System Tests | JS Verified? |
|---------|-----------------|-------------|--------------|
| Pin add/remove/clear | 11 tests | None | **No** |
| Touch (mark read) | 14 tests | None | **No** |
| Feed subscribe/unsubscribe | 19 tests | 1 test | **Partial** |
| Folder CRUD | 8 tests | None | **No** |
| Config get/set | 6 tests | 1 test | **Partial** |
| Mobile read/pin | 6 tests | None | **No** |

### WELL COVERED

| Feature | Test Type | Tests |
|---------|-----------|-------|
| Authentication (login/logout) | System + Controller | 8+ |
| JSON API responses | Controller | 97 |
| Model validations | Model | 55 |
| IDOR security | Controller | 8+ |
| Routing | Routing | 11 |

## Recommended Additional Tests for Migration

### Priority 1: Before Phase 2 (DOM/Event Changes)

```ruby
# test/system/reader_keyboard_test.rb
class ReaderKeyboardTest < ApplicationSystemTestCase
  # Tests needed:
  # - 's' key opens feed search
  # - 'j'/'k' keys navigate articles
  # - 'p' key toggles pin
  # - 'v' key opens article in browser
  # - 'o' key opens article
  # - Space key scrolls/advances
end

# test/system/reader_feed_display_test.rb
class ReaderFeedDisplayTest < ApplicationSystemTestCase
  # Tests needed:
  # - Feed list renders correctly
  # - Clicking feed loads articles
  # - Article body displays correctly
  # - Unread count updates
end
```

### Priority 2: Before Phase 3 (Extension Changes)

```ruby
# test/system/reader_pin_test.rb
class ReaderPinTest < ApplicationSystemTestCase
  # Tests needed:
  # - Pin article via UI click
  # - Unpin article via UI click
  # - Pin list displays correctly
end

# test/system/reader_mark_read_test.rb
class ReaderMarkReadTest < ApplicationSystemTestCase
  # Tests needed:
  # - Mark single article as read
  # - Mark all articles as read
  # - Unread count decrements
end
```

### Priority 3: Before Phase 4 (Class Changes)

```ruby
# test/system/reader_folder_test.rb
class ReaderFolderTest < ApplicationSystemTestCase
  # Tests needed:
  # - Folder tree displays
  # - Expand/collapse folder
  # - Feed count per folder
end
```

## Test Environment Details

### Configuration

```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  # Options: --no-sandbox
end

# test/test_helper.rb
parallelize(workers: 1)  # Single worker (no parallelization)
Minitest::Retry.use!(retry_count: 15) if ENV["CI"]
WebMock.disable_net_connect!(allow_localhost: true)
```

### Execution

```bash
bin/rails test              # All tests (~258 tests)
bin/rails test:system       # System tests only (11 tests)
bin/rails test test/system/ # Same as above
```

## Coverage Summary

```
                    API Layer    UI Layer (System Test)
                    ---------    ---------------------
Authentication      ✅ Full      ✅ Full
Feed Subscribe      ✅ Full      ✅ Partial (click only)
Feed Display        ❌ N/A       ❌ None
Article Reading     ❌ N/A       ❌ None
Keyboard Shortcuts  ❌ N/A       ❌ None
Pin Operations      ✅ Full      ❌ None
Mark as Read        ✅ Full      ❌ None
Folder Operations   ✅ Full      ❌ None
Config Changes      ✅ Full      ✅ Partial
Mobile Operations   ✅ Full      ❌ None
```

**Conclusion**: API layer is well-tested, but UI/JavaScript layer has significant gaps. The Prototype.js migration primarily affects the UI layer, making these gaps a risk factor. Adding System Tests for critical reader UI operations before starting Phase 2 is strongly recommended.
