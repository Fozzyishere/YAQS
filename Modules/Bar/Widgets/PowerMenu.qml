import QtQuick

import "../../../Commons"
import "../../../Widgets"

IconButton {
    id: root

    property var screen: null
    property real scaling: 1.0

    icon: ""  // Nerd Font: fa-power-off
    size: Math.round(Settings.data.ui.iconSize * scaling)
    iconColor: Settings.data.colors.mPrimary
    onClicked: {
        // TODO: Toggle power menu panel (shutdown, restart, logout, lock)
        Logger.log("PowerMenu", "Clicked");
    }
}
