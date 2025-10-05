import QtQuick

import "../../../Commons"
import "../../../Widgets"

IconButton {
  id: root

  property real scaling: 1.0

  icon: ""  // Nerd Font: fa-bars (menu icon)
  size: Math.round(Theme.icon_size * scaling)
  iconColor: Theme.purple

  onClicked: {
    // TODO: Toggle launcher panel
    Logger.log("AppLauncher", "Clicked")
  }
}