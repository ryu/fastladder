# CSP Audit Report

**Date**: 2026-02-08
**Phase**: CSP Phase 1 (report-only mode)

## Nonce Generator Feasibility

- `request.session.respond_to?(:id)` = `true`
- Nonce generator is feasible but **disabled in Phase 1**
- Phase 2 will use `SecureRandom.base64(32)` for nonce generation

## Inline Scripts

### HAML `:javascript` filter (3 files)

| File | Line | Content |
|------|------|---------|
| `layouts/application.html.haml` | 34 | ApiKey variable assignment |
| `mobile/index.html.haml` | 33 | Keyboard shortcut setup |
| `mobile/read_feed.html.haml` | 35 | Keyboard navigation |

**Note**: HAML `:javascript` filter does NOT support automatic nonce injection. Phase 2 must convert to `javascript_tag` helper.

### ERB `<script>` tags (7 files, 10 occurrences)

| File | Line | Content |
|------|------|---------|
| `reader/index.html.erb` | 473 | ApiKey + helper functions |
| `share/index.html.erb` | 68 | ApiKey variable |
| `subscribe/index.html.erb` | 22 | ApiKey variable |
| `subscribe/confirm.html.erb` | 107 | ApiKey variable |
| `subscribe/confirm.html.erb` | 109 | `init()` call |
| `user/index.html.erb` | 64 | Page-specific script |
| `import/fetch.html.erb` | 2 | Import UI logic |
| `utility/bookmarklet/index.html.erb` | 5 | Bookmarklet code |
| `utility/bookmarklet/index.html.erb` | 20 | Bookmarklet code |

## Inline Styles

### HAML `:css` filter (2 files)

| File | Line |
|------|------|
| `mobile/index.html.haml` | 27 |
| `mobile/read_feed.html.haml` | 29 |

### Inline `style=""` attributes

Numerous inline style attributes throughout `reader/index.html.erb` and other views. These are allowed by default CSP (`style-src` only restricts `<style>` blocks, not `style` attributes unless `style-src-attr` is set).

## Inline Event Handlers (onclick, onsubmit, etc.)

**High volume** - primarily in template HTML that is rendered via JavaScript:

| File | Count | Types |
|------|-------|-------|
| `reader/index.html.erb` | 30+ | onclick, onmouseover, onmouseout, onmousedown, onmouseup |
| `contents/manage.html.erb` | 15+ | onclick, onmouseover, onmouseout, onmousedown, onchange |
| `share/index.html.erb` | 10+ | onclick, onsubmit |
| `import/fetch.html.erb` | 4 | onclick |
| `subscribe/confirm.html.erb` | 5 | onclick, onkeydown, onmousedown, onsubmit, onchange |
| `contents/edit.html.erb` | 2 | onchange, onclick |
| `contents/configure.html.haml` | 2 | onclick |
| `about/_feed.html.erb` | 1 | onclick, onkeydown, onmousedown |

**Note**: Many of these are in JavaScript template strings (`reader/index.html.erb` lines 250-460) that get injected via `.fill()` template interpolation. These will NOT trigger CSP violations because they are inserted into the DOM via `innerHTML`, not parsed by the HTML parser with CSP enforcement.

## eval() Usage (2 files)

| File | Line | Code | Purpose |
|------|------|------|---------|
| `lib/reader/view.js` | 20 | `eval("Control."+action)` | Dynamic method dispatch |
| `lib/reader/ajax.js` | 69 | `eval("var str = TT."+$1)` | Template variable resolution |

**Phase 2 replacements**:
- `view.js`: `Control[action]()` (bracket notation)
- `ajax.js`: Property path resolution without eval

## javascript: URLs (1 file, 2 occurrences)

| File | Line | Purpose |
|------|------|---------|
| `utility/bookmarklet/index.html.erb` | 17 | Bookmarklet subscription link |
| `utility/bookmarklet/index.html.erb` | 54 | Firefox RSS handler registration |

**Note**: These are intentional bookmarklet URLs. They will trigger CSP violations but are expected behavior for bookmarklets.

## .js.erb Templates

None found.

## External API Calls

All XHR calls use `XMLHttpRequest` to same-origin paths (`/api/*`, `/rpc/*`). No external domain API calls detected. `connect_src :self` is appropriate.

## img_src Rationale

`img_src :self, :data, :https` is required because:
- RSS feed items contain `<img>` tags with external HTTPS URLs
- Favicon images may come from external sources
- `data:` URIs are used for some inline images

## CSP Violation Summary (Expected in Report-Only Mode)

| Category | Count | Severity | Phase |
|----------|-------|----------|-------|
| Inline scripts (HAML) | 3 | Medium | Phase 2 |
| Inline scripts (ERB) | 10 | Medium | Phase 2 |
| eval() | 2 | High | Phase 2 |
| javascript: URLs | 2 | Low | Bookmarklet-specific |
| Inline event handlers | 70+ | N/A | Not blocked by script-src |
| Inline styles (HAML) | 2 | Low | Phase 2 |

**Note**: Inline event handlers (`onclick`, etc.) are controlled by `script-src-attr` directive, which is NOT set in our policy. They will continue to work even in enforce mode unless `script-src-attr` is explicitly restricted.

## Phase 2 Roadmap

1. Convert HAML `:javascript` to `javascript_tag` helper (nonce support)
2. Convert ERB `<script>` to `javascript_tag` helper
3. Replace `eval()` with bracket notation / property path resolution
4. Enable nonce generator
5. Switch to enforce mode
