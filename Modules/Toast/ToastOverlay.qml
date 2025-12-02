import QtQuick
import Quickshell
import "../../Commons" as QsCommons

Variants {
  model: Quickshell.screens.filter(screen => {
    const monitors = QsCommons.Settings.data.notifications?.monitors || []
    // Show on selected monitors, or all if none specified
    return monitors.includes(screen.name) || monitors.length === 0
  })

  delegate: ToastScreen {
    required property ShellScreen modelData
    screen: modelData
  }
}
