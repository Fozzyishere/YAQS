// MVP FOR TESTING PURPOSES ONLY, WILL BE REPLACED SOON!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// --- IGNORE ---

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../Commons" as QsCommons
import "../../Services" as QsServices

Item {
  id: root

  required property ShellScreen screen

  // Track currently displayed notification ID to avoid duplicates
  property string currentNotificationId: ""

  // Watch for new notifications in activeList
  Connections {
    target: QsServices.NotificationService.activeList

    function onCountChanged() {
      // Show the most recent notification (first in list)
      if (QsServices.NotificationService.activeList.count > 0) {
        const notif = QsServices.NotificationService.activeList.get(0)
        
        // Only show if it's a different notification
        if (notif.id !== root.currentNotificationId) {
          root.currentNotificationId = notif.id
          root.showNotification(notif)
        }
      }
    }
  }

  // Debug on creation
  Component.onCompleted: {
    QsCommons.Logger.i("ToastScreen", "Initialized for screen:", screen.name)
  }

  // Cleanup on destruction
  Component.onDestruction: {
    currentNotificationId = ""
    if (windowLoader.active) {
      windowLoader.active = false
    }
  }

  // Show notification
  function showNotification(notif) {
    QsCommons.Logger.i("ToastScreen", "Showing notification:", notif.summary)

    // Store notification for when loader is ready
    windowLoader.pendingNotification = notif

    // Activate loader to create window
    windowLoader.active = true
  }

  // Called when toast is dismissed
  function onToastDismissed(notifId) {
    if (notifId === root.currentNotificationId) {
      root.currentNotificationId = ""
    }

    // Deactivate loader to destroy window (memory efficiency)
    windowLoader.active = false
  }

  // Loader creates/destroys PanelWindow on demand (memory efficient)
  Loader {
    id: windowLoader
    active: false

    // Store pending notification data
    property var pendingNotification: null

    onStatusChanged: {
      // When loader is ready, show the pending notification
      if (status === Loader.Ready && pendingNotification !== null) {
        item.showNotification(pendingNotification)
        pendingNotification = null
      }
    }

    sourceComponent: PanelWindow {
      id: panel

      property alias toastItem: toastItem

      screen: root.screen

      // Toast location from settings
      readonly property string location: {
        if (QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.location) {
          return QsCommons.Settings.data.notifications.location
        }
        return "top_right"
      }

      // Position calculations
      readonly property bool isTop: (location === "top") || (location.startsWith("top_"))
      readonly property bool isBottom: (location === "bottom") || (location.startsWith("bottom_"))
      readonly property bool isLeft: location.indexOf("_left") >= 0
      readonly property bool isRight: location.indexOf("_right") >= 0
      readonly property bool isCentered: (location === "top" || location === "bottom")

      // Anchor to screen edges based on location
      anchors.top: isTop
      anchors.bottom: isBottom
      anchors.left: isLeft
      anchors.right: isRight

      // Bar-aware margins (prevent overlap with bar)
      margins.top: {
        if (!anchors.top) return 0
        
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "top") {
          var floatExtraV = QsCommons.Settings.data.bar.floating ? 
                            QsCommons.Settings.data.bar.marginVertical * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtraV
        }
        return base
      }

      margins.bottom: {
        if (!anchors.bottom) return 0
        
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "bottom") {
          var floatExtraV = QsCommons.Settings.data.bar.floating ? 
                            QsCommons.Settings.data.bar.marginVertical * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtraV
        }
        return base
      }

      margins.left: {
        if (!anchors.left) return 0
        
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "left") {
          var floatExtraH = QsCommons.Settings.data.bar.floating ? 
                            QsCommons.Settings.data.bar.marginHorizontal * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtraH
        }
        return base
      }

      margins.right: {
        if (!anchors.right) return 0
        
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "right") {
          var floatExtraH = QsCommons.Settings.data.bar.floating ? 
                            QsCommons.Settings.data.bar.marginHorizontal * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtraH
        }
        return base
      }

      implicitWidth: 420
      implicitHeight: toastItem.height

      color: QsCommons.Color.transparent

      // Layer configuration (Top or Overlay)
      WlrLayershell.layer: {
        if (QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.overlayLayer) {
          return WlrLayer.Overlay
        }
        return WlrLayer.Top
      }
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: PanelWindow.ExclusionMode.Ignore

      // Show notification
      function showNotification(notif) {
        toastItem.showNotification(notif)
      }

      // Toast UI component
      SimpleToast {
        id: toastItem
        anchors.horizontalCenter: parent.horizontalCenter
        onDismissed: (notifId) => root.onToastDismissed(notifId)
      }
    }
  }
}
