import QtQuick
import Quickshell
import Quickshell.Io
import "Commons" as QsCommons
import "Services" as QsServices
import "Modules/Toast" as Toast

ShellRoot {
  id: shellRoot

  property bool settingsLoaded: false

  Component.onCompleted: {
    QsCommons.Logger.i("Shell", "YAQS Starting...")
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
        QsCommons.Logger.i("Shell", "Settings loaded successfully")

        // Initialize theming services
        QsServices.WallpaperService.init()
        QsServices.ColorSchemeService.init()
        QsServices.AppThemeService.init()
        QsServices.DarkModeService.init()
        QsServices.FontService.init()
        
        // Initialize location service (for weather and dark mode)
        QsServices.LocationService.init()

        // Force early initialization of device services
        var _ = QsServices.BrightnessService.monitors
        QsServices.NetworkService.init()
        
        // Force BluetoothService initialization for D-Bus adapter discovery
        var _bt = QsServices.BluetoothService.available
        
        // Force MediaService initialization for MPRIS discovery
        var _media = QsServices.MediaService.currentPlayer

        QsCommons.Logger.i("Shell", "All services initialized")
        QsCommons.Logger.i("Shell", "YAQS ready")
      }
    }
  }

  // === Toast Overlay ===
  // Displays transient notifications across all screens
  Toast.ToastOverlay {}
}
