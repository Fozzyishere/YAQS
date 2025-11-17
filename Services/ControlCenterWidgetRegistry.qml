pragma Singleton

import QtQuick
import Quickshell
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Widget Catalog ===
  // Maps widget ID → Component definition
  property var widgets: ({
    "WiFi": wifiComponent,
    "Bluetooth": bluetoothComponent,
    "Notifications": notificationsComponent,
    "ScreenRecorder": screenRecorderComponent,
    "WallpaperSelector": wallpaperSelectorComponent
  })

  // === Widget Metadata ===
  // CC widgets have minimal configuration (simple toggles)
  property var widgetMetadata: ({
    "WiFi": {
      "allowUserSettings": false,
      "icon": "wifi",
      "tooltip": "WiFi"
    },
    
    "Bluetooth": {
      "allowUserSettings": false,
      "icon": "bluetooth",
      "tooltip": "Bluetooth"
    },
    
    "Notifications": {
      "allowUserSettings": false,
      "icon": "bell",
      "tooltip": "Notifications"
    },
    
    "ScreenRecorder": {
      "allowUserSettings": false,
      "icon": "video",
      "tooltip": "Screen Recorder"
    },
    
    "WallpaperSelector": {
      "allowUserSettings": false,
      "icon": "photo",
      "tooltip": "Wallpaper"
    }
  })

  // === Component Definitions ===
  // TODO: waiting for UI implementations
  // For now, define as null to allow registry to exist before UI implementation
  property Component wifiComponent: null
  property Component bluetoothComponent: null
  property Component notificationsComponent: null
  property Component screenRecorderComponent: null
  property Component wallpaperSelectorComponent: null

  // === Initialization ===
  function init() {
    const widgetCount = Object.keys(widgets).length
    QsCommons.Logger.i("ControlCenterWidgetRegistry", "Initialized with", widgetCount, "widgets")
    
    // Validate: all widgets should have metadata
    let missingMetadata = 0
    for (const id in widgets) {
      if (!widgetMetadata[id]) {
        QsCommons.Logger.w("ControlCenterWidgetRegistry", "Widget missing metadata:", id)
        missingMetadata++
      }
    }
    
    if (missingMetadata > 0) {
      QsCommons.Logger.w("ControlCenterWidgetRegistry", missingMetadata, "widgets missing metadata")
    }
    
    // Validate: all metadata entries have corresponding widgets
    for (const id in widgetMetadata) {
      if (!(id in widgets)) {
        QsCommons.Logger.w("ControlCenterWidgetRegistry", "Metadata without widget:", id)
      }
    }
    
    QsCommons.Logger.d("ControlCenterWidgetRegistry", "All widgets are toggles (no user settings)")
  }

  // === Lookup Functions ===

  function getWidget(id) {
    // Returns Component definition or null
    if (!id) {
      QsCommons.Logger.w("ControlCenterWidgetRegistry", "getWidget called with empty id")
      return null
    }
    
    const component = widgets[id] || null
    if (!component) {
      QsCommons.Logger.w("ControlCenterWidgetRegistry", "Widget not found:", id)
    }
    
    return component
  }

  function hasWidget(id) {
    // Check if widget exists in catalog
    return id in widgets
  }

  function getAvailableWidgets() {
    // Returns array of all widget IDs
    return Object.keys(widgets).sort()
  }

  function widgetHasUserSettings(id) {
    // CC widgets don't have user settings
    return false
  }

  function getWidgetMetadata(id) {
    // Returns metadata object or empty object
    if (!widgetMetadata[id]) {
      QsCommons.Logger.w("ControlCenterWidgetRegistry", "No metadata for widget:", id)
      return {}
    }
    return widgetMetadata[id]
  }

  function getWidgetIcon(id) {
    // Get widget icon name
    const meta = widgetMetadata[id]
    return meta?.icon || "help-circle"
  }

  function getWidgetTooltip(id) {
    // Get widget tooltip text
    const meta = widgetMetadata[id]
    return meta?.tooltip || id
  }
}
