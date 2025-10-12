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

        // Initialize new services for testing
        NetworkService.checkAvailability();
        BrightnessService.detectBackend();
        MediaService.updateCurrentPlayer();  // Initialize media player tracking
    }

    // Floating top bar on all monitors
    Bar {}

    // Launcher panel
    Launcher {
        screen: Quickshell.screens[0] || null
    }

    // Session menu panel
    SessionMenu {
        screen: Quickshell.screens[0] || null
    }
}
