// Native JavaScript Method Preservation Shim
// This script MUST be loaded BEFORE any legacy JavaScript that pollutes prototypes.
// It saves references to native methods that Stimulus/Turbo depend on.

console.log('DEBUG: native_shim.js loading');

(function() {
  'use strict';
  console.log('DEBUG: native_shim.js executing');

  // Save native methods before they get polluted
  window.__nativeJS__ = {
    // Array methods
    ArrayFrom: Array.from,
    ArrayPrototypeReduce: Array.prototype.reduce,
    ArrayPrototypeMap: Array.prototype.map,
    ArrayPrototypeFilter: Array.prototype.filter,
    ArrayPrototypeForEach: Array.prototype.forEach,
    ArrayPrototypeEvery: Array.prototype.every,
    ArrayPrototypeSome: Array.prototype.some,
    ArrayPrototypeIndexOf: Array.prototype.indexOf,
    ArrayPrototypeFind: Array.prototype.find,
    ArrayPrototypeFindIndex: Array.prototype.findIndex,
    ArrayPrototypeIncludes: Array.prototype.includes,
    ArrayPrototypeFlat: Array.prototype.flat,
    ArrayPrototypeFlatMap: Array.prototype.flatMap,

    // Object methods
    ObjectAssign: Object.assign,
    ObjectKeys: Object.keys,
    ObjectValues: Object.values,
    ObjectEntries: Object.entries,
    ObjectFromEntries: Object.fromEntries,

    // Set and Map
    Set: Set,
    Map: Map,
    WeakMap: WeakMap,
    WeakSet: WeakSet,
  };

  // Function to restore native methods (call this before Stimulus loads)
  window.__restoreNativeJS__ = function() {
    var native = window.__nativeJS__;

    // Restore Array methods
    if (native.ArrayFrom) Array.from = native.ArrayFrom;
    if (native.ArrayPrototypeReduce) Array.prototype.reduce = native.ArrayPrototypeReduce;
    if (native.ArrayPrototypeMap) Array.prototype.map = native.ArrayPrototypeMap;
    if (native.ArrayPrototypeFilter) Array.prototype.filter = native.ArrayPrototypeFilter;
    if (native.ArrayPrototypeForEach) Array.prototype.forEach = native.ArrayPrototypeForEach;
    if (native.ArrayPrototypeEvery) Array.prototype.every = native.ArrayPrototypeEvery;
    if (native.ArrayPrototypeSome) Array.prototype.some = native.ArrayPrototypeSome;
    if (native.ArrayPrototypeIndexOf) Array.prototype.indexOf = native.ArrayPrototypeIndexOf;
    if (native.ArrayPrototypeFind) Array.prototype.find = native.ArrayPrototypeFind;
    if (native.ArrayPrototypeFindIndex) Array.prototype.findIndex = native.ArrayPrototypeFindIndex;
    if (native.ArrayPrototypeIncludes) Array.prototype.includes = native.ArrayPrototypeIncludes;
    if (native.ArrayPrototypeFlat) Array.prototype.flat = native.ArrayPrototypeFlat;
    if (native.ArrayPrototypeFlatMap) Array.prototype.flatMap = native.ArrayPrototypeFlatMap;

    // Restore Set and Map (in case they were overwritten)
    if (native.Set) window.Set = native.Set;
    if (native.Map) window.Map = native.Map;
    if (native.WeakMap) window.WeakMap = native.WeakMap;
    if (native.WeakSet) window.WeakSet = native.WeakSet;

    console.log('Native JavaScript methods restored');
  };
})();
