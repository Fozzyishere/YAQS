import QtQuick

import "../../../Commons"
import "../../../Services"
import "../../../Widgets"

IconButton {
    id: root

    property var screen: null
    property real scaling: 1.0

    icon: ""  // Nerd Font: fa-bars (menu icon)
    size: Math.round(Style.iconSize * scaling)
    iconColor: Color.mPrimary  // Primary color

    onClicked: {
        const launcher = PanelService.getPanel("launcherPanel");
        if (launcher) {
            if (launcher.active && !launcher.isClosing) {
                launcher.close();
            } else {
                PanelService.openPanelFromWidget(launcher, root);
            }
        } else {
            Logger.warn("AppLauncher", "Launcher panel not registered");
        }
    }
}
