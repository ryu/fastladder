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

The following warnings are unrelated to Rails 8.1 migration:

```
test/models/feed_test.rb:75: warning: literal string will be frozen in the future
test/models/feed_test.rb:66: warning: literal string will be frozen in the future
```

These are Ruby 4.0 frozen string literal warnings and should be addressed separately.

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

## References

- [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html)
- [Upgrading Ruby on Rails Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [HTML5 Specification](https://html.spec.whatwg.org/)
