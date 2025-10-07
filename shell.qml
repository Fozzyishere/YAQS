import QtQuick
import Quickshell

import "Commons"
import "Services"
import "Modules/Bar"

ShellRoot {
    id: root

    Component.onCompleted: {
        Logger.log("Shell", "Shell started successfully");
    }

    // Floating top bar on all monitors
    Bar {}
}
