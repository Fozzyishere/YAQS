import QtQuick

import "../../../Commons"
import "../../../Services"
import "../../../Widgets"

IconButton {
    id: root

    property var screen: null
    property real scaling: 1.0

    icon: ""  // Nerd Font: fa-power-off
    size: Math.round(Settings.data.ui.iconSize * scaling)
    iconColor: Settings.data.colors.mPrimary
    onClicked: {
        const sessionMenu = PanelService.getPanel("sessionMenuPanel");
        if (sessionMenu) {
            sessionMenu.toggle(root);
        } else {
            Logger.warn("PowerMenu", "Session menu panel not registered");
        }
    }
}
