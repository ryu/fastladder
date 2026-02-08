# Class Conversion Strategy - Prototype.js Removal Project

## Class System Implementation Analysis

### Class.create()

```javascript
// Source: lib/utils/common.js:169-182
Class.create = function(traits){
    var f = function(){
        this.initialize.apply(this, arguments);
    };
    f.prototype.initialize = function(){};
    f.isClass = true;
    f.extend = function(other){
        extend(f.prototype, other);
        return f;
    };
    if(traits && Class.Traits[traits])
        f.extend(Class.Traits[traits]);
    return f;
};
```

**Behavior**: Creates a constructor function that calls `this.initialize()` on instantiation.

**ES6 Equivalent**:
```javascript
class ClassName {
    constructor(...args) {
        // initialize logic here
    }
}
```

### Class.base()

```javascript
// Source: lib/utils/common.js:184-196
Class.base = function(base_class){
    if(base_class.isClass){
        var child = Class.create();
        child.prototype = new base_class;
        return child;
    } else {
        var base = Class();
        base.prototype = base_class;
        var child = Class.create();
        child.prototype = new base;
        return child;
    }
};
```

**Behavior**: Prototypal inheritance - child inherits parent's prototype.

**ES6 Equivalent**:
```javascript
class ChildClass extends ParentClass {
    constructor(...args) {
        super(...args);
    }
}
```

### Class.merge()

```javascript
// Source: lib/utils/common.js:198-215
Class.merge = function(a, b){
    var c = Class.create();
    var ap = a.prototype;
    var bp = b.prototype;
    var cp = c.prototype;
    var methods = Array.concat(keys(ap), keys(bp)).uniq();
    foreach(methods, function(key){
        if(isFunction(ap[key]) && isFunction(bp[key])){
            cp[key] = function(){
                ap[key].apply(this, arguments);
                return bp[key].apply(this, arguments);
            }
        } else {
            cp[key] =
                isFunction(ap[key]) ? ap[key] :
                isFunction(bp[key]) ? bp[key] : null
        }
    });
    return c;
};
```

**Behavior**: Mixin composition - merges two class prototypes. If both classes define the same method, creates a wrapper that calls both (A first, then B, returning B's result).

**ES6 Equivalent**: No direct equivalent. Options:
1. Manual method composition in subclass
2. Mixin function pattern
3. Object spread for simple cases

```javascript
// Option 1: Mixin function
function merge(ClassA, ClassB) {
    class Merged {
        constructor(...args) {
            // Call both initializers
        }
    }
    // Copy methods, compose duplicates
    for (const key of Object.getOwnPropertyNames(ClassA.prototype)) {
        if (key === 'constructor') continue;
        const aMethod = ClassA.prototype[key];
        const bMethod = ClassB.prototype[key];
        if (typeof aMethod === 'function' && typeof bMethod === 'function') {
            Merged.prototype[key] = function(...args) {
                aMethod.apply(this, args);
                return bMethod.apply(this, args);
            };
        } else {
            Merged.prototype[key] = aMethod || bMethod;
        }
    }
    // Copy B-only methods
    for (const key of Object.getOwnPropertyNames(ClassB.prototype)) {
        if (key === 'constructor' || Merged.prototype[key]) continue;
        Merged.prototype[key] = ClassB.prototype[key];
    }
    return Merged;
}
```

## Complexity Classification

### Criteria

| Level | Definition |
|-------|-----------|
| **Simple** | `Class.create()` only, no inheritance, no merge |
| **Medium** | `Class.create().extend({...})` with method definitions |
| **Complex** | `Class.merge()` or `Class.base().extend()` patterns |

### Full Classification

#### Simple (18 classes) - Convert first

| Class | File | Conversion Pattern |
|-------|------|-------------------|
| Cookie | `lib/utils/common.js` | `Class.create().extend({...})` → `class Cookie { constructor() {...} }` |
| Cache | `lib/utils/common.js` | Same pattern |
| Roma | `lib/utils/roma.js` | Same pattern |
| Trigger | `lib/events/event_dispatcher.js` | Same pattern |
| Hook | `lib/reader/event_hook.js` | Same pattern |
| LDR.API | `lib/api.js` | Same pattern |
| LDR.Queue | `lib/models/queue.js` | Same pattern |
| Pin | `lib/models/pin.js` | Same pattern (but later merged) |
| Pinsaver | `lib/models/pin.js` | Same pattern (but later merged) |
| FeedFormatter | `lib/ui/feed.js` | Same pattern |
| ItemFormatter | `lib/ui/item.js` | Same pattern |
| LDR.FlatMenu | `lib/ui/flat_menu.js` | Same pattern |
| Slider | `lib/ui/flat_menu.js` | Same pattern |
| LDRWidgets | `lib/reader/main.js` | Same pattern |
| Cart | `lib/reader/manage.js` | Same pattern |
| TreeView | `lib/reader/folder.js` | Same pattern |
| ListView | `lib/reader/addon.js` | Same pattern |
| DOMArray | `lib/reader/addon.js` | Same pattern |

#### Medium (13 classes with .extend()) - Convert second

| Class | File | Notes |
|-------|------|-------|
| LDR.Rate | `lib/ui/rate.js` | .extend() adds methods |
| LDR.EventTrigger | `lib/reader/event_hook.js` | .extend() adds methods |
| ToggleBase | `lib/reader/main.js` | Used in merge compositions |
| ShowFolder | `lib/reader/main.js` | Used in merge compositions |
| ShowViewmode | `lib/reader/main.js` | Used in merge/base compositions |
| Subscribe.View | `lib/reader/main.js` | .extend() adds methods |
| Subscribe.Controller | `lib/reader/main.js` | .extend() adds methods |
| Selector | `lib/reader/manage.js` | Used in merge |
| SelectorWithCart | `lib/reader/manage.js` | Used in merge |
| ListItem | `lib/reader/folder.js` | Used in base inheritance |
| Subscribe.Model | `lib/reader/subscriber.js` | .extend() adds methods |
| Subscribe.Collection | `lib/reader/subscriber.js` | .extend() adds methods |
| LDReader.Folder | `lib/subscribe/subscribe.js` | .extend() adds methods |
| ReaderSubscribe | `lib/subscribe/subscribe.js` | .extend() adds methods |

#### Complex (9 compositions) - Convert last

| Result | Pattern | Sources | ES6 Strategy |
|--------|---------|---------|-------------|
| FolderToggle | `Class.merge()` | ToggleBase + ShowFolder | Mixin function or manual composition |
| ViewmodeToggle | `Class.merge()` | ToggleBase + ShowViewmode | Same |
| SortmodeToggle | `Class.merge()` | ToggleBase + ShowSortmode | Same |
| ItemSelector | `Class.merge()` | Selector + SelectorWithCart | Same |
| Pin (merged) | `Class.merge()` | Pin + Pinsaver | Combine into single class |
| ShowSortmode | `Class.base().extend()` | extends ShowViewmode | `class ShowSortmode extends ShowViewmode` |
| MenuItem | `Class.base().extend()` | extends ListItem | `class MenuItem extends ListItem` |
| PinItem | `Class.base().extend()` | extends ListItem | `class PinItem extends ListItem` |
| SubsItem | `Class.base().extend()` | extends ListItem | `class SubsItem extends ListItem` |

## Conversion Rules

### Rule 1: Simple Class.create().extend({...})

```javascript
// BEFORE
var Cookie = Class.create();
Cookie.extend({
    initialize: function(opt) {
        this._options = "name,value".split(",");
    },
    get: function(key) {
        return this._index[key];
    }
});

// AFTER
class Cookie {
    constructor(opt) {
        this._options = "name,value".split(",");
    }
    get(key) {
        return this._index[key];
    }
}
```

### Rule 2: Class.base() inheritance

```javascript
// BEFORE
var MenuItem = Class.base(ListItem).extend({
    initialize: function(data) {
        // ...
    },
    render: function() {
        // ...
    }
});

// AFTER
class MenuItem extends ListItem {
    constructor(data) {
        super();
        // ... (original initialize logic, excluding super call)
    }
    render() {
        // ...
    }
}
```

### Rule 3: Class.merge() composition

```javascript
// BEFORE
var FolderToggle = Class.merge(ToggleBase, ShowFolder);

// AFTER - Option A: Keep merge utility during transition
const FolderToggle = merge(ToggleBase, ShowFolder);

// AFTER - Option B: Manual composition (preferred for final state)
class FolderToggle {
    constructor(...args) {
        // Initialize both aspects
    }
    toggle() {
        // ToggleBase.toggle logic
        // ShowFolder.toggle logic (if exists)
    }
    // ... other methods
}
```

### Rule 4: Function.bind/curry/later in class methods

```javascript
// BEFORE (inside Class.create)
initialize: function() {
    this.handler = this.onClick.bindThis(this);
    this.delayed = this.update.later(1000);
    this.partial = this.render.curry("html");
}

// AFTER (inside ES6 class)
constructor() {
    this.handler = this.onClick.bind(this);
    this.delayed = () => setTimeout(() => this.update(), 1000);
    this.partial = (...args) => this.render("html", ...args);
}
```

## Phase 1 Verification: Sample Class Selection

### Recommended: `Cookie` class

**Why Cookie?**
- Simple complexity (no inheritance, no merge)
- Small method count (~5 methods)
- Self-contained (no external class dependencies)
- Easy to verify (cookie read/write behavior)
- Located in `lib/utils/common.js` (core file, tests conversion in critical file)

**Alternative: `LDR.Queue`**
- Also Simple complexity
- Slightly more representative (uses array operations)
- Located in separate file (`lib/models/queue.js`)

### Recommended: Also test 1 Medium class

**Recommended: `LDR.Rate`**
- Medium complexity (.extend() pattern)
- Moderate method count
- Located in separate file (`lib/ui/rate.js`)
- Tests that .extend() → class method definition works

### Phase 1 Go/No-Go Criteria

| Criteria | Go | No-Go |
|----------|-----|-------|
| Simple class conversion time | < 30 min | > 2 hours |
| Medium class conversion time | < 1 hour | > 4 hours |
| Test pass rate after conversion | 100% | < 100% |
| Manual browser verification | All features work | Any feature broken |
| Unexpected complexity discovered | None | Circular dependencies, hidden state sharing |

### No-Go Alternative Strategy

If Phase 4 is deemed too risky:

1. **Keep Class.create as thin wrapper** - Rewrite `Class.create` to use ES6 class internally
2. **Gradual replacement** - New code uses ES6 class, old code keeps Class.create
3. **Freeze and document** - Keep current system, document as "legacy but stable"

## Conversion Order (within Phase 4)

```
Batch 1 (Simple, isolated):
  Cookie, Cache, Roma, LDR.Queue
  → Verify: tests pass, no regressions

Batch 2 (Simple, UI):
  FeedFormatter, ItemFormatter, LDR.FlatMenu, Slider
  → Verify: UI rendering correct

Batch 3 (Simple, core):
  Trigger, Hook, LDR.API, Pin, Pinsaver
  → Verify: event system works, API calls succeed

Batch 4 (Simple, reader):
  LDRWidgets, Cart, TreeView, ListView, DOMArray
  → Verify: reader UI functions

Batch 5 (Medium, UI):
  LDR.Rate, LDR.EventTrigger
  → Verify: rate display, event triggers

Batch 6 (Medium, reader):
  ToggleBase, ShowFolder, ShowViewmode
  Subscribe.View, Subscribe.Controller
  Selector, SelectorWithCart, ListItem
  Subscribe.Model, Subscribe.Collection
  LDReader.Folder, ReaderSubscribe
  → Verify: all reader interactions

Batch 7 (Complex, compositions):
  Class.base → ES6 extends: ShowSortmode, MenuItem, PinItem, SubsItem
  Class.merge: FolderToggle, ViewmodeToggle, SortmodeToggle, ItemSelector, Pin(merged)
  → Verify: all merged behaviors preserved

Batch 8 (Cleanup):
  Remove Class.create, Class.base, Class.merge from common.js
  → Verify: full test suite
```

## Risk Matrix

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `this` binding changes | Medium | High | Test each class individually |
| Merge composition breaks | Low | High | Keep `merge()` utility as bridge |
| Prototype chain differences | Low | Medium | Verify `instanceof` checks |
| Constructor call order | Low | Medium | Explicit `super()` calls |
| Static method loss | Low | Low | Add `static` keyword |
| Hidden global state | Medium | Medium | Audit shared variables per class |
