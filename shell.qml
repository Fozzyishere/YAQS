import QtQuick
import Quickshell
import "Commons" as QsCommons

ShellRoot {
  id: shellRoot

  property bool settingsLoaded: false

  Component.onCompleted: {
    QsCommons.Logger.i("Shell", "---------------------------")
    QsCommons.Logger.i("Shell", "YAQS Shell Loading...")
  }

  Connections {
    target: Quickshell
    function onReloadCompleted() {
      Quickshell.inhibitReloadPopup()
    }
  }

  Connections {
    target: QsCommons.Settings
    function onSettingsLoaded() {
      settingsLoaded = true
    }
  }

  Loader {
    active: settingsLoaded

    sourceComponent: Item {
      Component.onCompleted: {
        QsCommons.Logger.i("Shell", "---------------------------")
        QsCommons.Logger.i("Shell", "YAQS Hello!")
        QsCommons.Logger.i("Shell", "---------------------------")
        // Phase 2: Service initialization will go here
      }

      // Phase 4: Modules will go here
    }
  }
}
