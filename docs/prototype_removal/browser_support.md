# Browser Support - Prototype.js Removal Project

## Supported Browsers (Target)

After Prototype.js removal, Fastladder will target **modern browsers only**:

| Browser | Minimum Version | Notes |
|---------|----------------|-------|
| Chrome | 90+ | Primary development/test browser |
| Firefox | 88+ | Secondary support |
| Safari | 14+ | macOS/iOS support |
| Edge | 90+ | Chromium-based |

**Explicitly NOT supported:**
- Internet Explorer (all versions)
- Legacy Edge (non-Chromium)
- Opera Mini

## Current IE-Specific Code (To Be Removed)

### Summary: 12 locations across 7 files + 1 view

### Detailed List

#### 1. `lib/utils/ie_xmlhttp.js` (entire file - 45 lines)
- **Purpose**: XMLHttpRequest polyfill for IE6 and below
- **Implementation**: `ActiveXObject("Microsoft.XMLHTTP")` wrapper
- **Action**: Delete entire file

#### 2. `lib/utils/common.js` (line ~1166-1169)
- **Purpose**: IE opacity filter (`filter: alpha(opacity=...)`)
- **Detection**: `/MSIE/.test(navigator.userAgent)`
- **Action**: Remove IE branch, keep standard `opacity` only

#### 3. `lib/utils/common.js` (line ~1179-1182)
- **Purpose**: IE `currentStyle` fallback for CSS value retrieval
- **Action**: Remove IE branch, keep `getComputedStyle` only

#### 4. `lib/reader/main.js` (line ~113-115)
- **Purpose**: IE `currentStyle` fallback (duplicate pattern)
- **Action**: Remove IE branch

#### 5. `lib/reader/addon.js` (line ~981-983)
- **Purpose**: IE7-specific border width adjustment
- **Detection**: `navigator.userAgent.indexOf("MSIE 7")`
- **Action**: Remove entire block

#### 6. `lib/events/event_dispatcher.js` (lines ~50-52, 61-63, 75-76)
- **Purpose**: `attachEvent` vs `addEventListener` branching
- **Action**: Remove `attachEvent` branches, use `addEventListener` only

#### 7. `lib/round_corner.js` (line ~7-8)
- **Purpose**: `attachEvent` vs `addEventListener` branching
- **Action**: Remove `attachEvent` branch

#### 8. `lib/reader/event_trigger.js` (line ~29-31)
- **Purpose**: IE layout adjustment (`browser.isIE`)
- **Action**: Remove IE-specific width adjustment

#### 9. `lib/share/share.js` (line ~57-58)
- **Purpose**: IE CSS width exclusion (`!browser.isIE`)
- **Action**: Always apply `width = 100%`

#### 10. `lib/events/mouse_wheel.js` (lines ~5-13)
- **Purpose**: IE mouse wheel handling (`wheelDelta / -120`)
- **Action**: Use standard `wheel` event

#### 11. `app/views/share/index.html.erb` (lines 1-7)
- **Purpose**: IE7 conditional CSS (`<!--[if IE 7]>`)
- **Action**: Remove conditional comment block

## BrowserDetect Analysis

### Current Implementation (`lib/utils/common.js` lines 120-133)

Detects: IE, Firefox, Opera, Gecko, KHTML, Mac, Windows

### Usage Locations (7 files)

| File | Property Used | Purpose |
|------|--------------|---------|
| `reader/main.js` | Instance creation | Global browser detection |
| `reader/event_trigger.js` | `browser.isIE` | IE layout adjustment |
| `reader/ajax.js` | `browser.isKHTML` | KHTML ajax filter |
| `events/mouse_wheel.js` | `browser.isIE`, `browser.isOpera`, `browser.isGecko`, `browser.isKHTML` | Mouse wheel event branching |
| `round_corner.js` | `browser.isFirefox` | `-moz-border-radius` |
| `subscribe/subscribe.js` | `browser.isFirefox`, `browser.isKHTML` | Border radius + ajax filter |
| `share/share.js` | `browser.isIE` | CSS width exclusion |

### Recommended Action
- Replace `BrowserDetect` with feature detection where needed
- Most uses can be deleted entirely (IE/KHTML/Opera-specific code)
- Firefox `-moz-border-radius` is obsolete (standard `border-radius` works)
- Mouse wheel: replace with standard `wheel` event

## Modern JS Feature Usage

| Feature | Current Usage | Available in Target Browsers |
|---------|--------------|------------------------------|
| `const`/`let` | 1 file only (`updater.js`) | Yes (all targets) |
| Arrow functions | Not used | Yes (all targets) |
| Template literals | Not used | Yes (all targets) |
| ES6 `class` | Not used | Yes (all targets) |
| `import`/`export` | Not used | Yes (all targets) |
| `addEventListener` | Used alongside `attachEvent` | Yes (all targets) |
| `classList` | Not used | Yes (all targets) |
| `getComputedStyle` | Used alongside `currentStyle` | Yes (all targets) |
| `wheel` event | Not used (`mousewheel`/`DOMMouseScroll`) | Yes (all targets) |

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|-----------|
| Delete `ie_xmlhttp.js` | Low | No IE users expected |
| Remove `attachEvent` branches | Low | `addEventListener` already exists as primary path |
| Remove `currentStyle` fallback | Low | `getComputedStyle` is standard |
| Replace mouse wheel events | Medium | Need to verify `wheel` event behavior across browsers |
| Remove `BrowserDetect` | Low | Replace with feature detection where needed |
| Remove IE7 conditional CSS | Low | Dead code for modern browsers |
