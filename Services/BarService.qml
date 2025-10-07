pragma Singleton

import QtQuick
import Quickshell

import "../Commons"

Singleton {
    id: root

    // Widget instance registry
    // Key format: "screenName|section|widgetId|index"
    // Example: "eDP-1|left|AppLauncher|0"
    property var widgetInstances: ({})

    Component.onCompleted: {
        Logger.log("BarService", "Service initialized")
    }

    // ==================== Widget Registration ====================

    // Register a widget instance
    // Called by BarWidgetLoader when a widget is loaded
    function registerWidget(screenName, section, widgetId, index, instance) {
        const key = [screenName, section, widgetId, index].join("|")
        
        widgetInstances[key] = {
            "screenName": screenName,
            "section": section,
            "widgetId": widgetId,
            "index": index,
            "instance": instance
        }
        
        Logger.log("BarService", "Registered widget:", key)
    }

    // Unregister a widget instance
    // Called by BarWidgetLoader when a widget is destroyed
    function unregisterWidget(screenName, section, widgetId, index) {
        const key = [screenName, section, widgetId, index].join("|")
        delete widgetInstances[key]
        Logger.log("BarService", "Unregistered widget:", key)
    }

    // ==================== Widget Lookup ====================

    // Find first widget instance by ID
    // Optional screenName parameter to filter by screen
    // Returns: widget instance or null if not found
    //
    // Examples:
    //   lookupWidget("PowerMenu")           // First PowerMenu on any screen
    //   lookupWidget("Audio", "eDP-1")      // Audio widget on eDP-1 screen
    function lookupWidget(widgetId, screenName = null) {
        for (var key in widgetInstances) {
            var widget = widgetInstances[key]
            if (widget.widgetId === widgetId) {
                if (!screenName || widget.screenName === screenName) {
                    return widget.instance
                }
            }
        }
        return null
    }

    // Get all instances of a widget type
    // Returns: array of widget instances
    //
    // Examples:
    //   getAllWidgetInstances("Workspaces")  // All Workspaces widgets (one per screen)
    function getAllWidgetInstances(widgetId) {
        var instances = []
        for (var key in widgetInstances) {
            var widget = widgetInstances[key]
            if (widget.widgetId === widgetId) {
                instances.push(widget.instance)
            }
        }
        return instances
    }

    // Check if a widget exists
    // Returns: true if widget found, false otherwise
    function hasWidget(widgetId, screenName = null) {
        return lookupWidget(widgetId, screenName) !== null
    }

    // ==================== Debug/Utility ====================

    // Get list of all registered widget IDs (for debugging)
    // Returns: array of widget IDs
    function getAllRegisteredWidgets() {
        var result = []
        for (var key in widgetInstances) {
            result.push(widgetInstances[key].widgetId)
        }
        return result
    }

    // Get count of registered widgets
    function getWidgetCount() {
        return Object.keys(widgetInstances).length
    }

    // Get detailed info about all registered widgets (for debugging)
    function getDetailedRegistry() {
        var result = []
        for (var key in widgetInstances) {
            var widget = widgetInstances[key]
            result.push({
                "key": key,
                "widgetId": widget.widgetId,
                "section": widget.section,
                "screenName": widget.screenName,
                "index": widget.index
            })
        }
        return result
    }
}
