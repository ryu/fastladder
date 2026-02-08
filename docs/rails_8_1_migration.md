# Rails 8.1 Migration & Modernization Guide

## Overview

This document describes the migration from Rails 8.0 defaults to Rails 8.1 defaults for Fastladder, along with HTML5 modernization efforts.

**Migration Date**: 2026-02-05
**Commit**: 44824b7
**Rollback Tag**: `rails-8.0-final`

## Environment

| Component | Version |
|-----------|---------|
| Ruby | 4.0.1 |
| Rails | 8.1.2 |
| Database | SQLite3 |

## Changes Made

### Files Modified

1. **config/application.rb**
   ```ruby
   # Before
   config.load_defaults 8.0

   # After
   config.load_defaults 8.1
   ```

2. **config/initializers/new_framework_defaults_8_1.rb**
   - Deleted (all defaults now enabled via `load_defaults 8.1`)

## Rails 8.1 Default Settings

The following settings are now enabled:

| Setting | Value | Description |
|---------|-------|-------------|
| `escape_json_responses` | `false` | Improves JSON rendering performance by not escaping HTML entities |
| `render_tracker` | `:ruby` | Uses Ruby parser to track Action View template dependencies |
| `remove_hidden_field_autocomplete` | `true` | Hidden fields no longer include `autocomplete="off"` |
| `raise_on_missing_required_finder_order_columns` | `true` | Raises error for `.first`/`.last` without order when no fallback exists |
| `action_on_path_relative_redirect` | `:raise` | Raises error for relative URL redirects (security improvement) |

## Impact Analysis

### JSON API (`escape_json_responses = false`)

- **Affected files**: 11 files, 22 occurrences of `render json:`
- **Risk**: Low
- **Result**: All tests pass, XSS protection still works via Unicode escaping

### Finder Methods (`raise_on_missing_required_finder_order_columns = true`)

- **Affected files**: 6 files with `.first` usage
- **Analysis**:
  - `crawl_status.rb:28` - Already has explicit `order()` ✅
  - `rpc_controller.rb:41,47,52` - Uses unique constraints or primary key fallback ✅
  - `user_controller.rb:3` - Uses unique constraint (`members.username`) ✅
  - `import_controller.rb:22` - Array method, not ActiveRecord ✅
- **Result**: No code changes required

### Redirects (`action_on_path_relative_redirect = :raise`)

- **Affected files**: 7 files, 12 occurrences of `redirect_to`
- **Analysis**: All redirects use path helpers, absolute paths, or hash options
- **Result**: No relative URLs found, no changes required

### Hidden Fields (`remove_hidden_field_autocomplete = true`)

- **Affected files**: Form templates
- **Risk**: Low
- **Result**: No functional impact

## Database Schema Constraints

Relevant unique constraints that ensure `.first` safety:

| Table | Column(s) | Constraint |
|-------|-----------|------------|
| members | username | UNIQUE |
| feeds | feedlink | UNIQUE |
| subscriptions | (member_id, feed_id) | UNIQUE |

Note: `members.auth_key` does NOT have a unique constraint, but primary key fallback is used.

## Test Results

```
232 runs, 481 assertions, 0 failures, 0 errors, 0 skips
```

### Test Breakdown

| Category | Runs | Result |
|----------|------|--------|
| Controller tests | 92 | ✅ Pass |
| API tests | 44 | ✅ Pass |
| System tests | 11 | ✅ Pass |
| Model tests | 85 | ✅ Pass |

## Rollback Procedure

If issues are discovered after deployment:

```bash
# Option 1: Revert the commit
git revert 44824b7

# Option 2: Checkout the rollback tag
git checkout rails-8.0-final

# Then redeploy
bundle install
bin/rails db:migrate
```

## Known Warnings

~~Previously had frozen string literal warnings in `test/models/feed_test.rb:66, 75`~~

✅ **Resolved** in commit `da6181a` - Added `.dup` before `.force_encoding()` to fix Ruby 4.0 warnings.

## Migration Process

The migration followed a staged approach:

1. **Static Analysis** - Identified all affected code paths
2. **Staged Enablement** - Enabled each default one at a time
3. **Testing** - Ran full test suite after each change
4. **Verification** - QA engineer verified all functionality
5. **Code Review** - Confirmed minimal, correct changes
6. **Deployment** - Committed and pushed to remote

## Agent Workflow

| Agent | Role |
|-------|------|
| rails-architect | Created implementation plan |
| plan-reviewer | Critically reviewed and improved plan |
| logic-implementer | Executed the migration steps |
| qa-engineer | Verified implementation quality |
| code-reviewer | Final code review before merge |

---

## HTML5 Modernization

### Overview

Migrated legacy HTML doctypes to HTML5 standard across all layout files.

### Changes Made

#### 1. reader/index.html.erb

**Commit**: f3af2c4

```html
<!-- Before -->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=8">

<!-- After -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
```

**Removed legacy meta tags**:
- `http-equiv="content-type"` → `charset="utf-8"`
- `http-equiv="X-UA-Compatible"` (IE8 compatibility mode)
- `http-equiv="Content-Script-Type"` (removed in 8f380d2)
- `http-equiv="Content-Style-Type"` (removed in 8f380d2)

#### 2. application.html.haml

**Commit**: aad60a1

```haml
# Before
!!! 1.1
%html{"xml:lang": "en", xmlns: "http://www.w3.org/1999/xhtml"}

# After
!!! 5
%html{lang: "en"}
```

**Changes**:
- XHTML 1.1 DOCTYPE → HTML5 DOCTYPE
- Removed `xml:lang` and `xmlns` attributes
- Added standard `lang` attribute

### Verification

| Check | Result |
|-------|--------|
| I18n configuration | `default_locale` is `:en` (default) |
| I18n API usage | None (no `I18n.t` or `I18n.locale` calls) |
| CSS xmlns selector dependency | None |
| JS xmlns attribute reference | None |
| Test suite | All 232 tests pass |
| Layout consistency | Both files use `lang="en"` |

### Impact

- **Browser compatibility**: HTML5 is universally supported
- **Standards compliance**: Modern HTML5 standard
- **Accessibility**: Proper `lang` attribute for screen readers
- **SEO**: Correct language declaration for search engines

### Future Improvements (Out of Scope)

- Dynamic `lang` attribute with I18n integration (`lang: I18n.locale`)
- Add `<meta charset="utf-8">` to application.html.haml
- Audit other HAML files for consistency

---

## Mobile View Viewport Modernization

### Overview

Modernized mobile view viewport meta tags from fixed-width to responsive, improving accessibility by enabling pinch-zoom.

### Changes Made

#### 1. mobile/index.html.haml

**Commit**: 4b08b1f

```haml
# Before
%meta{name: "viewport", content: "width=320, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"}

# After
%meta{name: "viewport", content: "width=device-width, initial-scale=1.0"}
```

#### 2. mobile/read_feed.html.haml

**Commit**: 4b08b1f

```haml
# Before
%meta{name: "viewport", content: "width=320, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"}

# After
%meta{name: "viewport", content: "width=device-width, initial-scale=1.0"}
```

### What Changed

| Attribute | Before | After |
|-----------|--------|-------|
| `width` | `320` (fixed) | `device-width` (responsive) |
| `initial-scale` | `1.0` | `1.0` (unchanged) |
| `maximum-scale` | `1.0` (zoom disabled) | Removed (zoom allowed) |
| `user-scalable` | `no` (pinch-zoom disabled) | Removed (pinch-zoom allowed) |

### Verification

| Check | Result |
|-------|--------|
| CSS `width: 320px` dependency | None found |
| JavaScript viewport dependency | None found |
| Test suite | 258 runs, 535 assertions, 0 failures |
| Mobile controller tests | 6 runs, 16 assertions, 0 failures |
| Layout file (`layouts/mobile.html.haml`) | Already HTML5 (`!!! 5`) - no changes needed |

### Impact

- **Accessibility**: Complies with WCAG 2.1 SC 1.4.4 (Resize text) by allowing pinch-zoom
- **Responsive design**: Adapts to actual device width instead of fixed 320px
- **User experience**: Users can zoom in/out freely on mobile devices

### Agent Workflow

| Agent | Role |
|-------|------|
| rails-architect | Created implementation plan |
| plan-reviewer | Reviewed plan (no Must Fix items) |
| logic-implementer | Implemented viewport changes |
| qa-engineer | Verified tests and regression points |
| code-reviewer | Final code review before commit |

---

## Modernization Progress

### Completed Work

| Task | Commit | Date |
|------|--------|------|
| Rails 8.1 framework defaults | 44824b7 | 2026-02-05 |
| reader/index.html.erb HTML5 migration | f3af2c4 | 2026-02-05 |
| application.html.haml HTML5 migration | aad60a1 | 2026-02-05 |
| Legacy META tags removal | 8f380d2 | 2026-02-05 |
| Unused gems removal (jbuilder, ostruct) | eb5ef0c | 2026-02-05 |
| Frozen string literal warnings fix | da6181a | 2026-02-05 |
| Mobile view viewport modernization | 4b08b1f | 2026-02-08 |

### Future Candidates

- [ ] Turbo/Hotwire integration
- [ ] Legacy JS (Prototype.js) replacement
- [x] ~~Mobile view HTML5 migration~~
- [ ] I18n integration (dynamic `lang` attribute) - low priority

### Modernization Policy

**Incremental approach ("Small → Working → Grow")**:
- Don't break existing functionality
- Run tests after each change
- Small commits

---

## References

- [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html)
- [Upgrading Ruby on Rails Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [HTML5 Specification](https://html.spec.whatwg.org/)
