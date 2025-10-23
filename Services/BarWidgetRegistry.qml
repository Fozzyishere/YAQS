pragma Singleton

import QtQuick
import Quickshell

import "../Commons"
import "../Modules/Bar/Widgets"

Singleton {
    id: root

    property bool initialized: false

    // Widget component registry
    // Maps widget IDs to their Component definitions for lazy loading
    property var widgets: ({
        "AppLauncher": appLauncherComponent,
        "Clock": clockComponent,
        "WindowTitle": windowTitleComponent,
        "Workspaces": workspacesComponent,
        "Audio": audioComponent,
        "Battery": batteryComponent,
        "PowerMenu": powerMenuComponent,
        "WiFi": wifiComponent,
        "Brightness": brightnessComponent,
        "MediaMini": mediaMiniComponent
    })

    // Widget metadata registry
    // Maps widget IDs to their default settings and configuration schema
    property var widgetMetadata: ({
        "Clock": {
            "allowUserSettings": true,
            "displayMode": "always",
            "timeFormat": "hh:mm AP",
            "dateFormat": "dddd, MMM d yyyy",
            "showDate": true,
            "showTime": true
        },
        "Audio": {
            "allowUserSettings": true,
            "displayMode": "onhover",  // "always", "onhover", "icononly"
            "showPercentage": true
        },
        "Brightness": {
            "allowUserSettings": true,
            "displayMode": "onhover",
            "showPercentage": true
        },
        "Battery": {
            "allowUserSettings": true,
            "displayMode": "onhover",
            "warningThreshold": 20,
            "showPercentage": true
        },
        "WiFi": {
            "allowUserSettings": true,
            "displayMode": "onhover",
            "showSignalStrength": true
        },
        "Workspaces": {
            "allowUserSettings": true,
            "displayMode": "always",
            "hideUnoccupied": true,
            "maxWorkspaces": 10
        },
        "WindowTitle": {
            "allowUserSettings": true,
            "displayMode": "always",
            "maxLength": 50,
            "showIcon": true
        },
        "MediaMini": {
            "allowUserSettings": true,
            "displayMode": "auto",  // auto-hide when no media
            "showAlbumArt": false,
            "maxTitleLength": 30
        },
        "AppLauncher": {
            "allowUserSettings": false,
            "displayMode": "always"
        },
        "PowerMenu": {
            "allowUserSettings": false,
            "displayMode": "always"
        }
    })

    // Component definitions (lazy loaded - only instantiated when needed)
    property Component appLauncherComponent: Component {
        AppLauncher {}
    }

    property Component clockComponent: Component {
        Clock {}
    }

    property Component windowTitleComponent: Component {
        WindowTitle {}
    }

    property Component workspacesComponent: Component {
        Workspaces {}
    }

    property Component audioComponent: Component {
        Audio {}
    }

    property Component batteryComponent: Component {
        Battery {}
    }

    property Component powerMenuComponent: Component {
        PowerMenu {}
    }

    property Component wifiComponent: Component {
        WiFi {}
    }

    property Component brightnessComponent: Component {
        Brightness {}
    }

    property Component mediaMiniComponent: Component {
        MediaMini {}
    }

    // ===== Initialization =====
    function init() {
        if (initialized) {
            Logger.warn("BarWidgetRegistry", "Already initialized");
            return;
        }

        Logger.log("BarWidgetRegistry", "Initializing...");
        Logger.log("BarWidgetRegistry", "Registered widgets:", getAllWidgetIds().join(", "));
        initialized = true;
        Logger.log("BarWidgetRegistry", "Initialization complete");
    }

    function getWidget(widgetId) {
        if (widgets.hasOwnProperty(widgetId)) {
            Logger.log("BarWidgetRegistry", "Retrieved widget component:", widgetId)
            return widgets[widgetId]
        }
        Logger.error("BarWidgetRegistry", "Widget not found:", widgetId)
        return null
    }

    function hasWidget(widgetId) {
        return widgets.hasOwnProperty(widgetId)
    }

    function getAllWidgetIds() {
        return Object.keys(widgets)
    }

    function widgetHasUserSettings(widgetId) {
        return (widgetMetadata[widgetId] !== undefined) &&
               (widgetMetadata[widgetId].allowUserSettings === true)
    }
}
