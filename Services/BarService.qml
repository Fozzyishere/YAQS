pragma Singleton

import QtQuick
import Quickshell
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Bar Visibility ===
  property bool isVisible: true

  // === Bar Registration ===
  // Tracks which screens have completed bar initialization
  property var readyBars: ({})

  signal barReadyChanged(string screenName)

  // === Widget Instance Registry ===
  // Key: "{screen}|{section}|{widgetId}|{index}"
  // Value: { key, screenName, section, widgetId, index, instance }
  property var widgetInstances: ({})

  signal activeWidgetsChanged()

  // === Visualizer Detection ===
  property bool hasAudioVisualizer: false

  Timer {
    id: visualizerCheckTimer
    interval: 100
    repeat: false
    onTriggered: {
      hasAudioVisualizer = false
      const widgets = getAllWidgetInstances("MediaMini")

      for (var i = 0; i < widgets.length; i++) {
        const widget = widgets[i]
        // Check if widget has showVisualizer property and it's enabled
        if (widget && widget.hasOwnProperty("showVisualizer") && widget.showVisualizer) {
          hasAudioVisualizer = true
          QsCommons.Logger.d("BarService", "Audio visualizer detected")
          break
        }
      }

      if (!hasAudioVisualizer) {
        QsCommons.Logger.d("BarService", "No audio visualizers active")
      }
    }
  }

  // === Initialization ===
  Component.onCompleted: {
    QsCommons.Logger.d("BarService", "Service started")
  }

  // === Bar Registration Functions ===

  function registerBar(screenName) {
    if (!readyBars[screenName]) {
      readyBars[screenName] = true
      QsCommons.Logger.d("BarService", "Bar ready on screen:", screenName)
      barReadyChanged(screenName)
    }
  }

  function isBarReady(screenName) {
    return readyBars[screenName] || false
  }

  // === Widget Instance Management ===

  function registerWidget(screenName, section, widgetId, index, instance) {
    if (!screenName || !section || !widgetId || instance === undefined) {
      QsCommons.Logger.e("BarService", "registerWidget: invalid parameters",
                         screenName, section, widgetId, instance)
      return
    }

    const key = [screenName, section, widgetId, index].join("|")

    widgetInstances[key] = {
      "key": key,
      "screenName": screenName,
      "section": section,
      "widgetId": widgetId,
      "index": index,
      "instance": instance
    }

    QsCommons.Logger.d("BarService", "Registered widget:", key)
    activeWidgetsChanged()

    // Check for visualizer updates
    if (widgetId === "MediaMini") {
      visualizerCheckTimer.restart()
    }
  }

  function unregisterWidget(screenName, section, widgetId, index) {
    const key = [screenName, section, widgetId, index].join("|")

    if (widgetInstances[key]) {
      delete widgetInstances[key]
      QsCommons.Logger.d("BarService", "Unregistered widget:", key)
      activeWidgetsChanged()

      // Check for visualizer updates
      if (widgetId === "MediaMini") {
        visualizerCheckTimer.restart()
      }
    } else {
      QsCommons.Logger.w("BarService", "Attempted to unregister non-existent widget:", key)
    }
  }

  // === Widget Lookup Functions ===

  // Lookup specific widget instance
  function lookupWidget(widgetId, screenName = null, section = null, index = null) {
    if (!widgetId) {
      QsCommons.Logger.w("BarService", "lookupWidget: widgetId required")
      return undefined
    }

    // Search for matching widget instance
    for (var key in widgetInstances) {
      var widget = widgetInstances[key]

      // Early continue if widgetId doesn't match
      if (widget.widgetId !== widgetId) continue
      
      // Check screenName if specified
      if (screenName && widget.screenName !== screenName) continue
      
      // Check section if specified
      if (section !== null && widget.section !== section) continue
      
      // Check index if specified
      if (index !== null && widget.index !== index) continue

      // All conditions matched
      return widget.instance
    }

    return undefined
  }

  // Get all instances of a widget type
  function getAllWidgetInstances(widgetId = null, screenName = null, section = null) {
    var instances = []

    for (var key in widgetInstances) {
      var widget = widgetInstances[key]

      var matches = true
      if (widgetId && widget.widgetId !== widgetId)
        matches = false
      if (screenName && widget.screenName !== screenName)
        matches = false
      if (section !== null && widget.section !== section)
        matches = false

      if (matches) {
        instances.push(widget.instance)
      }
    }

    return instances
  }

  // Check if widget type exists
  function hasWidget(widgetId, section = null, screenName = null) {
    for (var key in widgetInstances) {
      var widget = widgetInstances[key]
      if (widget.widgetId === widgetId) {
        if (section === null || widget.section === section) {
          if (!screenName || widget.screenName === screenName) {
            return true
          }
        }
      }
    }
    return false
  }

  // Get widget with full metadata
  function getWidgetWithMetadata(widgetId, screenName = null, section = null) {
    for (var key in widgetInstances) {
      var widget = widgetInstances[key]
      if (widget.widgetId === widgetId) {
        if (!screenName || widget.screenName === screenName) {
          if (section === null || widget.section === section) {
            return widget
          }
        }
      }
    }
    return undefined
  }

  // Get all widgets in a section (sorted by index)
  function getWidgetsBySection(section, screenName = null) {
    if (!section) {
      QsCommons.Logger.w("BarService", "getWidgetsBySection: section required")
      return []
    }

    var widgetData = []

    // Collect widget metadata with instances
    for (var key in widgetInstances) {
      var widget = widgetInstances[key]
      if (widget.section === section) {
        if (!screenName || widget.screenName === screenName) {
          widgetData.push({
            "instance": widget.instance,
            "index": widget.index,
            "widgetId": widget.widgetId,
            "key": widget.key
          })
        }
      }
    }

    // Sort by index to maintain order (ascending)
    widgetData.sort(function(a, b) {
      return a.index - b.index
    })

    // Extract just the instances in sorted order
    var instances = []
    for (var i = 0; i < widgetData.length; i++) {
      instances.push(widgetData[i].instance)
    }

    return instances
  }

  // Get all registered widgets (debugging)
  function getAllRegisteredWidgets() {
    var result = []
    for (var key in widgetInstances) {
      result.push({
        "key": key,
        "widgetId": widgetInstances[key].widgetId,
        "section": widgetInstances[key].section,
        "screenName": widgetInstances[key].screenName,
        "index": widgetInstances[key].index
      })
    }
    return result
  }

  // Count widgets
  function getWidgetCount(widgetId = null, section = null, screenName = null) {
    return getAllWidgetInstances(widgetId, screenName, section).length
  }

  // === Utility Functions ===

  // Get tooltip direction based on bar position
  function getTooltipDirection() {
    const position = QsCommons.Settings.data.bar.position

    switch (position) {
      case "right": return "left"
      case "left": return "right"
      case "bottom": return "top"
      case "top":
      default: return "bottom"
    }
  }

  // Get pill opening direction for widget
  function getPillDirection(widget) {
    if (!widget) return false

    try {
      const section = widget.section
      const index = widget.sectionWidgetIndex || 0
      const count = widget.sectionWidgetsCount || 1

      if (section === "left") {
        // Left section opens to the right
        return true
      } else if (section === "right") {
        // Right section opens to the left
        return false
      } else {
        // Center section: first half opens left, second half opens right
        return index >= count / 2
      }
    } catch (e) {
      QsCommons.Logger.e("BarService", "Error getting pill direction:", e)
    }

    return false
  }

  // Get bar height/width based on position
  function getBarSize() {
    return QsCommons.Style.barHeight
  }

  // Check if bar is horizontal
  function isHorizontalBar() {
    const position = QsCommons.Settings.data.bar.position
    return position === "top" || position === "bottom"
  }

  // Check if bar is vertical
  function isVerticalBar() {
    return !isHorizontalBar()
  }

  // === Debug Functions ===

  function logRegisteredWidgets() {
    const widgets = getAllRegisteredWidgets()
    QsCommons.Logger.i("BarService", "=== Registered Widgets ===")
    QsCommons.Logger.i("BarService", "Total count:", widgets.length)

    for (var i = 0; i < widgets.length; i++) {
      const w = widgets[i]
      QsCommons.Logger.i("BarService", "-", w.key)
    }
  }

  function logWidgetsBySection() {
    const sections = ["left", "center", "right"]
    QsCommons.Logger.i("BarService", "=== Widgets by Section ===")

    for (var s = 0; s < sections.length; s++) {
      const section = sections[s]
      const widgetData = []

      // Collect widgets with metadata
      for (var key in widgetInstances) {
        const widget = widgetInstances[key]
        if (widget.section === section) {
          widgetData.push({
            "widgetId": widget.widgetId,
            "index": widget.index
          })
        }
      }

      QsCommons.Logger.i("BarService", section + ":", widgetData.length, "widgets")

      // Sort by index
      widgetData.sort(function(a, b) {
        return a.index - b.index
      })

      for (var i = 0; i < widgetData.length; i++) {
        QsCommons.Logger.i("BarService", "  [" + widgetData[i].index + "]", widgetData[i].widgetId)
      }
    }
  }

  function getStatistics() {
    const total = Object.keys(widgetInstances).length
    const screens = {}
    const widgetTypes = {}

    for (var key in widgetInstances) {
      const widget = widgetInstances[key]
      screens[widget.screenName] = (screens[widget.screenName] || 0) + 1
      widgetTypes[widget.widgetId] = (widgetTypes[widget.widgetId] || 0) + 1
    }

    return {
      "total": total,
      "screens": screens,
      "widgetTypes": widgetTypes,
      "hasVisualizer": hasAudioVisualizer,
      "barsReady": Object.keys(readyBars).length
    }
  }
}
