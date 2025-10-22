import QtQuick
import Quickshell

import "../../Commons"
import "../../Services"

Item {
    id: root

    // Required properties from parent (Repeater delegate)
    required property string widgetId
    required property var screen
    required property real scaling

    // Optional properties for widget tracking
    property string section: ""        // "left", "center", "right"
    property int sectionIndex: 0       // Index within section

    // Widget metadata and settings support
    readonly property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] || {}
    readonly property var widgetSettings: getWidgetSettings()

    // Expose implicit size - only reserve space if widget is visible
    implicitWidth: loader.item ? (loader.item.visible ? loader.item.implicitWidth : 0) : 0
    implicitHeight: loader.item ? (loader.item.visible ? loader.item.implicitHeight : 0) : 0

    function getWidgetSettings() {
        if (section && sectionIndex >= 0) {
            const sectionWidgets = Settings.data.bar.widgets[section]
            if (sectionWidgets && sectionIndex < sectionWidgets.length) {
                return sectionWidgets[sectionIndex]
            }
        }
        return {}
    }

    Loader {
        id: loader

        anchors.fill: parent
        active: widgetId !== ""

        // Load widget component from registry
        sourceComponent: {
            if (!active) {
                return null
            }
            return BarWidgetRegistry.getWidget(widgetId)
        }

        onLoaded: {
            if (!item) {
                Logger.error("BarWidgetLoader", "Failed to load widget:", widgetId)
                return
            }

            // Pass properties to loaded widget
            item.screen = root.screen
            item.scaling = root.scaling

            // Pass metadata and settings to widgets that support them
            if (item.hasOwnProperty("widgetId")) item.widgetId = root.widgetId
            if (item.hasOwnProperty("section")) item.section = root.section
            if (item.hasOwnProperty("sectionWidgetIndex")) item.sectionWidgetIndex = root.sectionIndex
            if (item.hasOwnProperty("widgetMetadata")) item.widgetMetadata = root.widgetMetadata
            if (item.hasOwnProperty("widgetSettings")) item.widgetSettings = root.widgetSettings

            // Register with BarService (add later)
            if (typeof BarService !== "undefined") {
                BarService.registerWidget(
                    root.screen.name,
                    root.section,
                    root.widgetId,
                    root.sectionIndex,
                    item
                )
            }

            Logger.log("BarWidgetLoader",
                      `Loaded widget: ${widgetId} [section=${section}, index=${sectionIndex}, screen=${root.screen.name}]`)
        }

        Component.onDestruction: {
            // Unregister widget when destroyed
            if (typeof BarService !== "undefined" && item) {
                BarService.unregisterWidget(
                    root.screen.name,
                    root.section,
                    root.widgetId,
                    root.sectionIndex
                )
                Logger.log("BarWidgetLoader", `Unregistered widget: ${widgetId}`)
            }
        }
    }

    // Error handling
    Component.onCompleted: {
        if (widgetId && !BarWidgetRegistry.hasWidget(widgetId)) {
            Logger.error("BarWidgetLoader", 
                        `Unknown widget ID: "${widgetId}" - Available widgets:`, 
                        BarWidgetRegistry.getAllWidgetIds().join(", "))
        }
    }
}

