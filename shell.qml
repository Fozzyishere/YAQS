import QtQuick
import Quickshell

import "Commons"
import "Modules/Bar"

ShellRoot {
  id: root

  Component.onCompleted: {
    Logger.log("Shell", "Minimalist Hyprland Shell started")
    Logger.log("Shell", "Bar launched")
  }

  // Floating top bar on all monitors
  Bar {}
}
