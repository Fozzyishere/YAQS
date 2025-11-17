pragma Singleton

import QtQuick
import Quickshell
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Widget Catalog ===
  // Maps widget ID → Component definition
  property var widgets: ({
    // === Core Widgets ===
    "Clock": clockComponent,
    "Workspace": workspaceComponent,
    "ActiveWindow": activeWindowComponent,
    "Volume": volumeComponent,
    "Brightness": brightnessComponent,
    "WiFi": wiFiComponent,
    "Bluetooth": bluetoothComponent,
    "Battery": batteryComponent,
    "Tray": trayComponent,
    
    // === Secondary Widgets ===
    "ControlCenter": controlCenterComponent,
    "NotificationHistory": notificationHistoryComponent,
    "SessionMenu": sessionMenuComponent,
    "MediaMini": mediaMiniComponent,
    "Microphone": microphoneComponent,
    "ScreenRecorder": screenRecorderComponent,
    "WallpaperSelector": wallpaperSelectorComponent,
    "DarkMode": darkModeComponent,
    "CustomButton": customButtonComponent,
    "Spacer": spacerComponent
  })

  // === Widget Metadata ===
  // Default configuration for each widget type
  property var widgetMetadata: ({
    // === Clock Widget ===
    "Clock": {
      "allowUserSettings": true,
      "usePrimaryColor": true,           // Use theme primary color
      "useCustomFont": false,            // Use custom font family
      "customFont": "",                  // Font family name
      "formatHorizontal": "HH:mm ddd, MMM dd",  // Top/bottom bar format
      "formatVertical": "HH mm - dd MM"  // Left/right bar format
    },
    
    // === Workspace Widget ===
    "Workspace": {
      "allowUserSettings": true,
      "labelMode": "index",              // "index", "name", "icon"
      "hideUnoccupied": false,           // Hide empty workspaces
      "characterCount": 2                // Max chars for name mode
    },
    
    // === ActiveWindow Widget ===
    "ActiveWindow": {
      "allowUserSettings": true,
      "showIcon": true,                  // Show window icon
      "hideMode": "hidden",              // "visible", "hidden", "transparent"
      "scrollingMode": "hover",          // "always", "hover", "never"
      "maxWidth": 145,                   // Max width in pixels
      "useFixedWidth": false,            // Force fixed width
      "colorizeIcons": false             // Apply theme color to icons
    },
    
    // === Volume Widget ===
    "Volume": {
      "allowUserSettings": true,
      "displayMode": "onhover"           // "always", "onhover", "icon_only"
    },
    
    // === Brightness Widget ===
    "Brightness": {
      "allowUserSettings": true,
      "displayMode": "onhover"           // "always", "onhover", "icon_only"
    },
    
    // === WiFi Widget ===
    "WiFi": {
      "allowUserSettings": true,
      "displayMode": "onhover"           // "always", "onhover", "icon_only"
    },
    
    // === Bluetooth Widget ===
    "Bluetooth": {
      "allowUserSettings": true,
      "displayMode": "onhover"           // "always", "onhover", "icon_only"
    },
    
    // === Battery Widget ===
    "Battery": {
      "allowUserSettings": true,
      "displayMode": "onhover",          // "always", "onhover", "icon_only"
      "warningThreshold": 30             // Battery warning percentage
    },
    
    // === Tray Widget ===
    "Tray": {
      "allowUserSettings": true,
      "blacklist": [],                   // Array of app IDs to hide
      "colorizeIcons": false             // Apply theme color to icons
    },
    
    // === ControlCenter Widget ===
    "ControlCenter": {
      "allowUserSettings": true,
      "useDistroLogo": false,            // Use distro logo instead of icon
      "icon": "apps",                    // Tabler icon name
      "customIconPath": ""               // Path to custom icon image
    },
    
    // === NotificationHistory Widget ===
    "NotificationHistory": {
      "allowUserSettings": true,
      "showUnreadBadge": true,           // Show unread count badge
      "hideWhenZero": true               // Hide badge when no notifications
    },
    
    // === SessionMenu Widget ===
    "SessionMenu": {
      "allowUserSettings": false         // No user settings for this widget
    },
    
    // === MediaMini Widget ===
    "MediaMini": {
      "allowUserSettings": true,
      "hideMode": "hidden",              // "visible", "hidden", "transparent"
      "scrollingMode": "hover",          // "always", "hover", "never"
      "maxWidth": 145,                   // Max width in pixels
      "useFixedWidth": false,            // Force fixed width
      "showAlbumArt": false,             // Show album artwork
      "showVisualizer": false,           // Show audio visualizer
      "visualizerType": "linear"         // "linear", "mirrored", "wave"
    },
    
    // === Microphone Widget ===
    "Microphone": {
      "allowUserSettings": true,
      "displayMode": "onhover"           // "always", "onhover", "icon_only"
    },
    
    // === ScreenRecorder Widget ===
    "ScreenRecorder": {
      "allowUserSettings": false         // No user settings for this widget
    },
    
    // === WallpaperSelector Widget ===
    "WallpaperSelector": {
      "allowUserSettings": false         // No user settings for this widget
    },
    
    // === DarkMode Widget ===
    "DarkMode": {
      "allowUserSettings": false         // No user settings for this widget
    },
    
    // === CustomButton Widget ===
    "CustomButton": {
      "allowUserSettings": true,
      "icon": "heart",                   // Tabler icon name
      "leftClickExec": "",               // Command for left click
      "rightClickExec": "",              // Command for right click
      "middleClickExec": "",             // Command for middle click
      "textCommand": "",                 // Command to get text output
      "textStream": false,               // Run textCommand continuously
      "textIntervalMs": 3000,            // Interval for streaming text
      "textCollapse": ""                 // Text to show when collapsed
    },
    
    // === Spacer Widget ===
    "Spacer": {
      "allowUserSettings": true,
      "width": 20                        // Spacer width in pixels
    }
  })

  // === Component Definitions ===
  // TODO: wait for UI
  // For now, define as null - this allows registry to exist before widgets

  // Core Widgets
  property Component clockComponent: null
  property Component workspaceComponent: null
  property Component activeWindowComponent: null
  property Component volumeComponent: null
  property Component brightnessComponent: null
  property Component wiFiComponent: null
  property Component bluetoothComponent: null
  property Component batteryComponent: null
  property Component trayComponent: null

  // Secondary Widgets
  property Component controlCenterComponent: null
  property Component notificationHistoryComponent: null
  property Component sessionMenuComponent: null
  property Component mediaMiniComponent: null
  property Component microphoneComponent: null
  property Component screenRecorderComponent: null
  property Component wallpaperSelectorComponent: null
  property Component darkModeComponent: null
  property Component customButtonComponent: null
  property Component spacerComponent: null

  // === Lookup Functions ===

  function getWidget(id) {
    // Returns Component definition or null
    if (!id) {
      QsCommons.Logger.w("BarWidgetRegistry", "getWidget called with empty id")
      return null
    }
    
    const component = widgets[id] || null
    if (!component) {
      QsCommons.Logger.w("BarWidgetRegistry", "Widget not found:", id)
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
    // Check if widget allows user configuration
    return (widgetMetadata[id] !== undefined) && 
           (widgetMetadata[id].allowUserSettings === true)
  }

  function getWidgetMetadata(id) {
    // Returns metadata object or empty object
    if (!widgetMetadata[id]) {
      QsCommons.Logger.w("BarWidgetRegistry", "No metadata for widget:", id)
      return {}
    }
    return widgetMetadata[id]
  }

  function getWidgetDefaultSetting(id, key) {
    // Get specific metadata field with fallback
    const meta = widgetMetadata[id]
    if (!meta) return undefined
    return meta[key]
  }

  // === Initialization ===

  function init() {
    // Count widgets
    const widgetCount = Object.keys(widgets).length
    const metadataCount = Object.keys(widgetMetadata).length
    
    QsCommons.Logger.i("BarWidgetRegistry", "Initialized with", widgetCount, "widgets")
    
    // Validate: every widget should have metadata
    let missingMetadata = 0
    for (const id in widgets) {
      if (!widgetMetadata[id] || widgetMetadata[id].allowUserSettings === undefined) {
        QsCommons.Logger.w("BarWidgetRegistry", "Widget missing metadata:", id)
        missingMetadata++
      }
    }
    
    if (missingMetadata > 0) {
      QsCommons.Logger.w("BarWidgetRegistry", missingMetadata, "widgets missing metadata")
    }
    
    // Log configurable widgets count
    const configurableCount = Object.keys(widgets).filter(id => 
      widgetHasUserSettings(id)
    ).length
    QsCommons.Logger.d("BarWidgetRegistry", configurableCount, "widgets have user settings")
  }
}
