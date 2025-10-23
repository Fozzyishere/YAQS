import QtQuick
import Quickshell

import qs.Commons
import qs.Services
import qs.Modules.Bar
import qs.Modules.Launcher
import qs.Modules.SessionMenu

ShellRoot {
    id: root

    Component.onCompleted: {
        Logger.log("Shell", "===========================================");
        Logger.log("Shell", "Initializing YAQS Shell...");
        Logger.log("Shell", "Settings version:", Settings.currentSettingsVersion);
        Logger.log("Shell", "===========================================");
        Logger.log("Shell", "");

        Logger.log("Shell", "Core Services");
        MatugenService.init();
        Logger.log("Shell", "");

        Logger.log("Shell", "Compositor Services");
        CompositorService.init();  // Detects and initializes compositor (and HyprlandService)
        Logger.log("Shell", "");

        Logger.log("Shell", "Hardware Services");
        AudioService.init();
        BatteryService.init();
        BrightnessService.init();
        NetworkService.init();
        MediaService.init();
        Logger.log("Shell", "");

        Logger.log("Shell", "UI Services");
        BarWidgetRegistry.init();
        TooltipService.init();
        PanelService.init();
        BarService.init();
        Logger.log("Shell", "");

        Logger.log("Shell", "===========================================");
        Logger.log("Shell", "YAQS initialization complete!");
        Logger.log("Shell", "===========================================");
    }

    // Floating top bar on all monitors
    Bar {}

    // Launcher panel
    Launcher {
        id: launcherPanel
        objectName: "launcherPanel"
    }

    // Session menu panel
    SessionMenu {
        id: sessionMenuPanel
        objectName: "sessionMenuPanel"
    }
}
