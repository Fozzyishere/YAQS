import QtQuick

import "../../../Commons"
import "../../../Widgets"

IconButton {
  id: root

  property real scaling: 1.0

  icon: ""  // Nerd Font: fa-power-off
  size: Math.round(Theme.icon_size * scaling)
  iconColor: Theme.urgent  // Red color for power

  onClicked: {
    // TODO: Toggle power menu panel (shutdown, restart, logout, lock)
    Logger.log("PowerMenu", "Clicked")
  }
}