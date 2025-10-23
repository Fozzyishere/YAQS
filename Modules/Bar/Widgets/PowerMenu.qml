import QtQuick

import qs.Commons
import qs.Services
import qs.Widgets

IconButton {
    id: root

    property var screen: null
    property real scaling: 1.0

    icon: ""  // Nerd Font: fa-power-off
    size: Math.round(Style.iconSize * scaling)
    iconColor: Color.mPrimary
    onClicked: {
        const sessionMenu = PanelService.getPanel("sessionMenuPanel");
        if (sessionMenu) {
            if (sessionMenu.active && !sessionMenu.isClosing) {
                sessionMenu.close();
            } else {
                PanelService.openPanelFromWidget(sessionMenu, root);
            }
        } else {
            Logger.warn("PowerMenu", "Session menu panel not registered");
        }
    }
}
