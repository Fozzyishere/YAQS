// Clipboard Plugin for YAQS Launcher
// Provides clipboard history browsing and search

import QtQuick
import qs.Commons
import qs.Services

Item {
  id: root

  // ===== Plugin Interface =====
  property var launcher: null
  property string name: "Clipboard"
  property bool handleSearch: false  // Command mode only

  // ===== Internal State =====
  property bool isWaitingForData: false
  property bool gotResults: false
  property string lastSearchText: ""

  // ===== Listen for Clipboard Updates =====
  Connections {
    target: ClipboardService
    function onListCompleted() {
      if (gotResults && (lastSearchText === searchText)) {
        // Do not update results after the first fetch.
        // This will avoid the list resetting every 5 seconds when the service updates.
        return
      }
      // Refresh results if we're waiting for data or if clipboard plugin is active
      if (isWaitingForData || (launcher && launcher.searchText.startsWith(">clip"))) {
        isWaitingForData = false
        gotResults = true
        if (launcher) {
          launcher.updateResults()
        }
      }
    }
  }

  // ===== Plugin Lifecycle =====
  function init() {
    Logger.log("ClipboardPlugin", "Initialized")
    // Pre-load clipboard data if service is active
    if (ClipboardService.active) {
      ClipboardService.list(100)
    }
  }

  function onOpened() {
    isWaitingForData = true
    gotResults = false
    lastSearchText = ""

    // Refresh clipboard history when launcher opens
    if (ClipboardService.active) {
      ClipboardService.list(100)
    }
  }

  function handleCommand(searchText) {
    return searchText.startsWith(">clip")
  }

  function commands() {
    return [{
              "name": ">clip",
              "description": "Browse clipboard history",
              "icon": "text-x-generic",
              "isImage": false,
              "onActivate": function () {
                launcher.setSearchText(">clip ")
              }
            }, {
              "name": ">clip clear",
              "description": "Clear clipboard history",
              "icon": "edit-clear",
              "isImage": false,
              "onActivate": function () {
                ClipboardService.wipeAll()
                launcher.close()
              }
            }]
  }

  function getResults(searchText) {
    if (!searchText.startsWith(">clip")) {
      return []
    }

    lastSearchText = searchText
    const results = []
    const query = searchText.slice(5).trim()

    // Check if clipboard service is not active
    if (!ClipboardService.active) {
      return [{
                "name": "Clipboard history is disabled",
                "description": "Install cliphist or enable in settings",
                "icon": "dialog-information",
                "isImage": false,
                "onActivate": function () {}
              }]
    }

    // Special command: clear
    if (query === "clear") {
      return [{
                "name": "Clear clipboard history",
                "description": "This will delete all clipboard history",
                "icon": "edit-clear-all",
                "isImage": false,
                "onActivate": function () {
                  ClipboardService.wipeAll()
                  launcher.close()
                }
              }]
    }

    // Show loading state if data is being loaded
    if (ClipboardService.loading || isWaitingForData) {
      return [{
                "name": "Loading clipboard history...",
                "description": "Please wait",
                "icon": "view-refresh",
                "isImage": false,
                "onActivate": function () {}
              }]
    }

    // Get clipboard items
    const items = ClipboardService.items || []

    // If no items and we haven't tried loading yet, trigger a load
    if (items.length === 0 && !ClipboardService.loading) {
      isWaitingForData = true
      ClipboardService.list(100)
      return [{
                "name": "Loading clipboard history...",
                "description": "Please wait",
                "icon": "view-refresh",
                "isImage": false,
                "onActivate": function () {}
              }]
    }

    // Search clipboard items
    const searchTerm = query.toLowerCase()

    // Filter and format results
    items.forEach(function (item) {
      const preview = (item.preview || "").toLowerCase()

      // Skip if search term doesn't match
      if (searchTerm && preview.indexOf(searchTerm) === -1) {
        return
      }

      // Format the result based on type
      let entry
      if (item.isImage) {
        entry = formatImageEntry(item)
      } else {
        entry = formatTextEntry(item)
      }

      // Add activation handler
      entry.onActivate = function () {
        ClipboardService.copyToClipboard(item.id)
        launcher.close()
      }

      results.push(entry)
    })

    // Show empty state if no results
    if (results.length === 0) {
      results.push({
                     "name": searchTerm ? "No matching clipboard items" : "Clipboard is empty",
                     "description": searchTerm ? `No items containing "${query}"` : "Copy something to see it here",
                     "icon": "text-x-generic",
                     "isImage": false,
                     "onActivate": function () {
                       // Do nothing
                     }
                   })
    }

    return results
  }

  // ===== Helper Functions =====

  // Format image clipboard entry
  function formatImageEntry(item) {
    const meta = parseImageMeta(item.preview)

    return {
      "name": meta ? `Image ${meta.w}×${meta.h}` : "Image",
      "description": meta ? `${meta.fmt} • ${meta.size}` : item.mime || "Image data",
      "icon": "image-x-generic",
      "isImage": true,
      "imageWidth": meta ? meta.w : 0,
      "imageHeight": meta ? meta.h : 0,
      "clipboardId": item.id,
      "mime": item.mime
    }
  }

  // Format text clipboard entry with preview
  function formatTextEntry(item) {
    const preview = (item.preview || "").trim()
    const lines = preview.split('\n').filter(l => l.trim())

    // Use first line as title, limit length
    let title = lines[0] || "Empty text"
    if (title.length > 60) {
      title = title.substring(0, 57) + "..."
    }

    // Use second line or character count as description
    let description = ""
    if (lines.length > 1) {
      description = lines[1]
      if (description.length > 80) {
        description = description.substring(0, 77) + "..."
      }
    } else {
      const chars = preview.length
      const words = preview.split(/\s+/).length
      description = `${chars} characters, ${words} word${words !== 1 ? 's' : ''}`
    }

    return {
      "name": title,
      "description": description,
      "icon": "text-x-generic",
      "isImage": false
    }
  }

  // Parse image metadata from preview string
  // Format: [[ binary data 245.6 KiB PNG 1920x1080 ]]
  function parseImageMeta(preview) {
    const re = /\[\[\s*binary data\s+([\d\.]+\s*(?:KiB|MiB|GiB|B))\s+(\w+)\s+(\d+)x(\d+)\s*\]\]/i
    const match = (preview || "").match(re)

    if (!match) {
      return null
    }

    return {
      "size": match[1],
      "fmt": (match[2] || "").toUpperCase(),
      "w": Number(match[3]),
      "h": Number(match[4])
    }
  }

  // Public method to get image data for a clipboard item
  function getImageForItem(clipboardId) {
    return ClipboardService.getImageData ? ClipboardService.getImageData(clipboardId) : null
  }
}
