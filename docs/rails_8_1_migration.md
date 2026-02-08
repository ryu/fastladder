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
| JS Phase 0-4: Class.create→ES6, DOM modernization | c81b89e以前 | 2026-02-06〜07 |
| JS Phase 5: Legacy utility functions→native JS | c81b89e | 2026-02-07 |
| JS Phase 6A: Low-frequency prototype method removal | (pending) | 2026-02-08 |

### Future Candidates

- [ ] Turbo/Hotwire integration
- [x] ~~Legacy JS (Prototype.js) replacement~~ Phase 0-6A complete, Phase 6B deferred
- [x] ~~Mobile view HTML5 migration~~
- [ ] I18n integration (dynamic `lang` attribute) - low priority
- [ ] JS Phase 6B: High-frequency prototype helpers (fill, _try, later, curry, toDF) - 72 occurrences

### Modernization Policy

**Incremental approach ("Small → Working → Grow")**:
- Don't break existing functionality
- Run tests after each change
- Small commits

---

## JavaScript Modernization: Phase 6 - Prototype Extension Cleanup

### Overview

Phase 6 focuses on cleaning up prototype extensions in `proto.js`. The approach is split into two phases based on cost-benefit analysis:

- **Phase 6A (Required)**: Replace low-frequency prototype methods (1-4 occurrences) with native JS
- **Phase 6B (Optional/Deferred)**: Keep high-frequency custom helpers (7-32 occurrences) as technical debt

### Background

Following Phase 5 completion (legacy utility functions modernized), `proto.js` still contains prototype extensions:

**String.prototype**:
- `.aroundTag()` - HTML tag wrapping
- `.fill()` - Template interpolation `[[key]]` → value

**Number.prototype**:
- `.toRelativeDate()` - Seconds → relative date string

**Array.prototype**:
- `.filter_by()`, `.sum()`, `.sum_of()`, `.toDF()`, `.asCallback()`, `.indexOfStr()`, `.mode()`, `.sort_by()`, `.like()`

**Function.prototype**:
- `.curry()` / `.bindArgs()` - Partial application
- `.later()` - Delayed execution wrapper
- `.next()` - Function chaining
- `._try()` - Safe error handling (defined in common.js)

### Phase 6A: Low-Frequency Method Replacement (Required)

#### Usage Analysis

| Method | Occurrences | Phase | Replacement Strategy |
|--------|-------------|-------|---------------------|
| `.aroundTag()` | 2 | 6A | Template literals |
| `.toRelativeDate()` | 2 | 6A | Helper function `toRelativeDate(seconds)` |
| `.filter_by()` | 2 | 6A | `.filter(v => v[attr] === value)` |
| `.asCallback()` | 1 | 6A | Inline function composition |
| `.indexOfStr()` | 3 | 6A | `.findIndex()` with string conversion |
| `.mode()` | 1 | 6A | Helper function `arrayMode(arr)` |
| `.sort_by()` | 3 | 6A | `.sort((a,b) => ...)` |
| `.like()` | 1 | 6A | `.find(v => v.startsWith(str))` |
| `.next()` | 4 | 6A | Inline wrapper functions |
| `.sum()` / `.sum_of()` | 4 | 6A | `.reduce((a,b) => a+b, 0)` |

**Total**: 23 occurrences across 11 methods

#### Phase 6B: High-Frequency Method Retention (Deferred)

| Method | Occurrences | Reason for Retention |
|--------|-------------|---------------------|
| `.fill()` | 32 | Template interpolation; would require extensive refactoring |
| `._try()` | 14 | Error handling; try-catch wrappers would be verbose |
| `.later()` | 12 | Delayed execution + cancellation; complex setTimeout wrapper |
| `.curry()` / `.bindArgs()` | 7 | Partial application; simpler than `.bind()` |
| `.toDF()` | 7 | DocumentFragment creation; useful helper |

**Total**: 72 occurrences across 5 methods (kept as technical debt)

### Implementation Plan

#### Step 6A-1: Document Replacement Strategy

**Deliverable**: `docs/phase6_prototype_cleanup_plan.md`

**Content**:
- Complete list of prototype methods
- Usage frequency for each method
- Phase 6A (replace) vs Phase 6B (keep) classification
- Specific replacement patterns

**Done Criteria**:
- All methods documented with usage counts
- Clear Phase 6A / 6B classification
- Replacement patterns specified

#### Step 6A-2: Replace String.prototype.aroundTag

**Scope**: 2 occurrences

**Replacement Pattern**:
```javascript
// Before
str.aroundTag("div")

// After
`<div>${str}</div>`
```

**Files**:
- `app/assets/javascripts/lib/ui/flat_menu.js`
- `app/assets/javascripts/lib/reader/main.js`

**Done Criteria**:
- 2 occurrences replaced
- Tests pass

#### Step 6A-3: Convert Number.prototype.toRelativeDate to Helper

**Scope**: 2 occurrences

**Replacement Pattern**:
```javascript
// Before
seconds.toRelativeDate()

// After
toRelativeDate(seconds)

// Helper function (in proto.js or utils.js)
function toRelativeDate(seconds) {
  const k = seconds > 0 ? seconds : -seconds;
  let u = "sec";
  const jp = { sec: "秒", min: "分", hour: "時間", day: "日", Mon: "ヶ月" };
  const vec = seconds >= 0 ? "前" : "後";
  let st = 0;
  let value = k;

  if (value >= 60) { value /= 60; u = "min"; st = 1; }
  if (st && value >= 60) { value /= 60; u = "hour"; st = 1; } else { st = 0; }
  if (st && value >= 24) { value /= 24; u = "day"; st = 1; } else { st = 0; }
  if (st && value >= 30) { value /= 30; u = "Mon"; st = 1; } else { st = 0; }

  const floored = Math.floor(value);
  const v = jp[u];
  return isNaN(floored) ? "nan" : floored + v + vec;
}
```

**Files**:
- `app/assets/javascripts/lib/reader/commands.js`
- `app/assets/javascripts/lib/reader/manage.js`

**Done Criteria**:
- Helper function defined
- 2 occurrences replaced
- Tests pass

#### Step 6A-4: Replace Array Methods Batch 1

**Scope**: 4 occurrences

**Replacement Patterns**:
```javascript
// filter_by (2 occurrences)
// Before: arr.filter_by("status", "active")
// After: arr.filter(v => v.status === "active")

// asCallback (1 occurrence)
// Before: [fn1, fn2].asCallback()
// After: () => { fn1(); fn2(); }

// mode (1 occurrence)
// Before: arr.mode()
// After: arrayMode(arr)
// Helper: function arrayMode(arr) { /* existing logic */ }
```

**Files**:
- `app/assets/javascripts/lib/reader/subscriber.js` (filter_by: 2, mode: 1)
- `app/assets/javascripts/lib/reader/commands.js` (asCallback: 1)

**Done Criteria**:
- 4 occurrences replaced
- Helper function `arrayMode()` defined
- Tests pass

#### Step 6A-5: Replace Array Methods Batch 2

**Scope**: 11 occurrences

**Replacement Patterns**:
```javascript
// indexOfStr (3 occurrences)
// Before: arr.indexOfStr(searchElement, fromIndex)
// After: arr.findIndex((v, i) => i >= (fromIndex || 0) && String(v) === String(searchElement))

// sort_by (3 occurrences)
// Before: arr.sort_by("priority")
// After: arr.sort((a, b) => a.priority === b.priority ? 0 : a.priority < b.priority ? 1 : -1)

// like (1 occurrence)
// Before: arr.like("prefix")
// After: arr.find(v => v.startsWith("prefix"))

// sum (1 occurrence in subscriber.js, 1 internal in proto.js)
// Before: arr.sum()
// After: arr.reduce((acc, v) => acc + v, 0)

// sum_of (2 occurrences)
// Before: arr.sum_of("count")
// After: arr.map(v => v.count).reduce((acc, v) => acc + v, 0)
```

**Files**:
- `app/assets/javascripts/lib/reader/main.js` (indexOfStr: 3, sort_by: 2)
- `app/assets/javascripts/lib/reader/manage.js` (sort_by: 1)
- `app/assets/javascripts/lib/reader/addon.js` (like: 1)
- `app/assets/javascripts/lib/reader/subscriber.js` (sum: 1, sum_of: 2)
- `app/assets/javascripts/lib/utils/proto.js` (sum internal usage: 1)

**Done Criteria**:
- 11 occurrences replaced
- Tests pass

#### Step 6A-6: Replace Function.prototype.next

**Scope**: 4 occurrences

**Replacement Pattern**:
```javascript
// Before
fn.next(afterFn)

// After
function fnWithNext(...args) {
  const res = fn.apply(this, args);
  afterFn();
  return res;
}
```

**Files**:
- `app/assets/javascripts/lib/reader/main.js` (4 occurrences)

**Done Criteria**:
- 4 inline wrappers created
- Tests pass

#### Step 6A-7: Remove Replaced Methods from proto.js

**Content**:
Remove method definitions for:
- `String.prototype.aroundTag`
- `Number.prototype.toRelativeDate` (keep helper function)
- `Array.prototype.filter_by`
- `Array.prototype.asCallback`
- `Array.prototype.indexOfStr`
- `Array.prototype.mode` (keep helper function)
- `Array.prototype.sort_by`
- `Array.prototype.like`
- `Array.prototype.sum`
- `Array.prototype.sum_of`
- `Function.prototype.next`

**Keep in proto.js** (Phase 6B):
- `String.prototype.fill`
- `Function.prototype.curry`
- `Function.prototype.bindArgs`
- `Function.prototype.later`
- `Array.prototype.toDF`
- `Function.prototype._try` (in common.js)

**Done Criteria**:
- All replaced methods removed from proto.js
- Helper functions (`toRelativeDate`, `arrayMode`) properly placed
- Tests pass
- System tests pass

#### Step 6A-8: Update Documentation

**Content**:
Update `docs/rails_8_1_migration.md` with:
- Phase 6A completion record
- List of remaining methods (Phase 6B)
- Technical debt notation for deferred methods
- Future refactoring considerations

**Done Criteria**:
- Documentation updated
- Completion date recorded

### Test Strategy

**Automated Tests**:
- `bin/rails test` - All unit/integration tests
- `bin/rails test:system` - Selenium-based UI tests

**Manual Verification**:
1. Open feed reader UI
2. Verify sorting functionality (sort_by replacement)
3. Check relative date display (toRelativeDate replacement)
4. Test filtering features (filter_by replacement)
5. Verify search autocomplete (like replacement)

### Quality Gate

**Required**:
- All 232 tests pass
- System tests pass
- No JavaScript console errors

**Manual Checks**:
- Feed list display works
- Sorting functions correctly
- Date formatting correct
- Filtering works as expected

### Completion Status

All Phase 6A steps completed in a single commit:

| Step | Status |
|------|--------|
| 6A-1: Document plan | ✅ Documented in this file |
| 6A-2: aroundTag → template literals | ✅ 2 occurrences replaced |
| 6A-3: toRelativeDate → helper function | ✅ 2 occurrences + helper in common.js |
| 6A-4: filter_by, asCallback, mode | ✅ 4 occurrences + arrayMode helper |
| 6A-5: indexOfStr, sort_by, like, sum, sum_of | ✅ 11 occurrences replaced |
| 6A-6: Function.prototype.next | ✅ 4 occurrences inlined |
| 6A-7: Remove from proto.js | ✅ 11 methods removed |
| 6A-8: Update documentation | ✅ This section |

### Risk Analysis

| Risk Level | Impact | Mitigation |
|------------|--------|------------|
| Low | Syntax errors from replacements | Automated tests catch immediately |
| Low | Behavioral changes | System tests verify UI functionality |
| Medium | Missed occurrences | Grep verification before proto.js cleanup |
| Medium | Phase 6B technical debt | Document clearly for future work |

### Phase 6B: Future Considerations

**High-frequency methods kept as technical debt**:

1. **`.fill()` (32 occurrences)** - Template interpolation
   - Future: Migrate to template literals or dedicated template engine

2. **`._try()` (14 occurrences)** - Error handling
   - Future: Standard try-catch blocks or error boundary pattern

3. **`.later()` (12 occurrences)** - Delayed execution
   - Future: Promise-based delay utility or modern async patterns

4. **`.curry()` / `.bindArgs()` (7 occurrences)** - Partial application
   - Future: Use `.bind()` or convert to helper function

5. **`.toDF()` (7 occurrences)** - DocumentFragment creation
   - Future: Convert to standalone helper function

**Estimated effort for Phase 6B**: Medium (40-60 hours)
**Priority**: Low (Phase 6A provides sufficient modernization value)

### Agent Workflow

| Agent | Role |
|-------|------|
| rails-architect | Created Phase 6A/6B split plan |
| plan-reviewer | Reviewed and approved cost-benefit split |
| logic-implementer | Execute replacement steps |
| qa-engineer | Verify tests and manual checks |
| code-reviewer | Final review before commits |

---

## References

- [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html)
- [Upgrading Ruby on Rails Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [HTML5 Specification](https://html.spec.whatwg.org/)
