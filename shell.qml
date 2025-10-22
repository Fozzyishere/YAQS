import QtQuick
import Quickshell

import "Commons"
import "Services"
import "Modules/Bar"
import "Modules/Launcher"
import "Modules/SessionMenu"

ShellRoot {
    id: root

    Component.onCompleted: {
        Logger.log("Shell", "Shell started successfully");

        // Initialize core services
        MatugenService.init();  // Initialize theme service

        // Initialize hardware services
        NetworkService.checkAvailability();
        BrightnessService.detectBackend();
        MediaService.updateCurrentPlayer();  // Initialize media player tracking
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
