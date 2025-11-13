// MVP FOR TESTING PURPOSES ONLY, WILL BE REPLACED SOON!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// --- IGNORE ---



import QtQuick
import Quickshell
import "../../Commons" as QsCommons

Item {
  // Debug logging
  Component.onCompleted: {
    QsCommons.Logger.i("ToastOverlay", "Initialized")
    QsCommons.Logger.i("ToastOverlay", "Screens:", Quickshell.screens.length)
    QsCommons.Logger.i("ToastOverlay", "Toast enabled:", QsCommons.Settings.data.toast?.enabled ?? true)
  }

  Variants {
    model: Quickshell.screens.filter(screen => {
      const monitors = QsCommons.Settings.data.toast?.monitors || []
      const enabled = QsCommons.Settings.data.toast?.enabled ?? true
      if (!enabled) return false
      return monitors.includes(screen.name) || monitors.length === 0
    })

    delegate: ToastScreen {
      required property ShellScreen modelData
      screen: modelData
    }
  }
}
