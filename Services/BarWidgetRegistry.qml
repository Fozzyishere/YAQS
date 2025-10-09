pragma Singleton

import QtQuick
import Quickshell

import "../Commons"
import "../Modules/Bar/Widgets"

Singleton {
    id: root

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

    Component.onCompleted: {
        Logger.log("BarWidgetRegistry", "Initialized with widgets:", getAllWidgetIds().join(", "))
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
}
