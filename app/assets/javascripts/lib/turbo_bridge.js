/*
 * Turbo Stream Bridge for LDR JavaScript
 *
 * This bridge enhances LDR.API to support Turbo Stream responses
 * alongside traditional JSON responses. It provides a non-invasive
 * way to progressively enhance the reader with Turbo Stream updates.
 *
 * Usage:
 * - Include this file AFTER lib/api.js and AFTER Turbo is loaded
 * - API calls to supported endpoints will automatically request Turbo Stream
 * - If Turbo Stream is returned, it's applied via Turbo.renderStreamMessage
 * - JSON responses continue to work as before
 */

(function() {
  "use strict";

  // Exit early if LDR.API is not available
  if (typeof LDR === "undefined" || typeof LDR.API === "undefined") {
    console.warn("TurboBridge: LDR.API not found, bridge not initialized");
    return;
  }

  // Endpoints that support Turbo Stream responses
  var TURBO_ENDPOINTS = [
    "/api/pin/add",
    "/api/pin/remove",
    "/api/pin/clear",
    "/api/touch_all",
    "/api/feed/set_rate",
    "/api/feed/move",
    "/api/feed/set_public",
    "/api/feed/unsubscribe",
    "/api/folder/create",
    "/api/folder/update",
    "/api/folder/delete"
  ];

  // Store original post method
  var originalPost = LDR.API.prototype.post;

  // Check if an endpoint supports Turbo Stream
  function supportsTurboStream(endpoint) {
    return TURBO_ENDPOINTS.some(function(ep) {
      return endpoint.indexOf(ep) !== -1;
    });
  }

  // Check if Turbo is available
  function turboAvailable() {
    return typeof window.Turbo !== "undefined" &&
           typeof window.Turbo.renderStreamMessage === "function";
  }

  // Enhanced post method with Turbo Stream support
  LDR.API.prototype.post = function(param, onload) {
    var self = this;

    // Use original implementation if Turbo is not available or endpoint doesn't support it
    if (!turboAvailable() || !supportsTurboStream(this.ap)) {
      return originalPost.call(this, param, onload);
    }

    // Create request
    this.req = new XMLHttpRequest();
    var onloadFn = onload || this.onload;
    var oncomplete = this.onComplete;

    if (typeof onloadFn !== "function") {
      onloadFn = function() {};
    }

    // Extend params with sticky query
    if (LDR.API.StickyQuery) {
      for (var key in LDR.API.StickyQuery) {
        if (LDR.API.StickyQuery.hasOwnProperty(key)) {
          param[key] = LDR.API.StickyQuery[key];
        }
      }
    }

    // Build query string
    var postdata = Object.toQuery ? Object.toQuery(param) : serializeParams(param);

    this.req.open("POST", this.ap, true);
    this.req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    // Request both Turbo Stream and JSON, preferring Turbo Stream
    this.req.setRequestHeader("Accept", "text/vnd.turbo-stream.html, application/json, */*");

    this.req.onload = function() {
      oncomplete();
      LDR.API.last_response = self.req.responseText;

      var contentType = self.req.getResponseHeader("Content-Type") || "";

      if (contentType.indexOf("turbo-stream") !== -1) {
        // Handle Turbo Stream response
        try {
          window.Turbo.renderStreamMessage(self.req.responseText);
          // Call onload with success indicator
          onloadFn({ isSuccess: true, turboStream: true });
        } catch (e) {
          console.error("TurboBridge: Error rendering Turbo Stream", e);
          // Fall back to treating as error
          if (self.onerror) {
            self.onerror(-1);
          }
        }
      } else {
        // Handle JSON response (original behavior)
        if (self.raw_mode) {
          onloadFn(self.req.responseText);
        } else {
          try {
            var json = JSON.parse(self.req.responseText);
            if (json) {
              onloadFn(json);
            } else {
              message("Unable to load data");
              if (typeof show_error === "function") show_error();
            }
          } catch (e) {
            message("Unable to load data");
            if (typeof show_error === "function") show_error();
          }
        }
      }
      self.req = null;
    };

    this.req.onerror = function() {
      oncomplete();
      if (self.onerror) {
        self.onerror(-1);
      }
      self.req = null;
    };

    this.onCreate();
    this.req.send(postdata);
    return this;
  };

  // Fallback serialization if Object.toQuery is not available
  function serializeParams(params) {
    var parts = [];
    for (var key in params) {
      if (params.hasOwnProperty(key)) {
        var value = params[key];
        if (typeof value !== "function") {
          parts.push(
            encodeURIComponent(key) + "=" + encodeURIComponent(value)
          );
        }
      }
    }
    return parts.join("&");
  }

  // Log initialization
  if (typeof console !== "undefined" && console.log) {
    console.log("TurboBridge: LDR.API enhanced with Turbo Stream support");
  }

})();
