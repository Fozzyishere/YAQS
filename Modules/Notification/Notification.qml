import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Commons" as QsCommons
import "../../Services" as QsServices

// Notification overlay - displays active notifications per configured screen
// Uses full-screen PanelWindow with Region mask (nixnew pattern) for unrestricted movement
Variants {
  id: root

  // Show on configured monitors (or all if none specified)
  model: Quickshell.screens.filter(screen => {
    const monitors = QsCommons.Settings.data.notifications?.monitors || []
    return monitors.includes(screen.name) || monitors.length === 0
  })

  delegate: Loader {
    id: screenLoader
    required property ShellScreen modelData

    // Access the notification model from the service
    property ListModel notificationModel: QsServices.NotificationService.activeList

    // Loader is active when there are notifications or during exit animation
    active: notificationModel.count > 0 || delayTimer.running

    // Keep loader active briefly after last notification to allow animations to complete
    Timer {
      id: delayTimer
      interval: QsCommons.Style.animationSlow + 200
      repeat: false
    }

    // Start delay timer when last notification is removed
    Connections {
      target: notificationModel
      function onCountChanged() {
        if (notificationModel.count === 0 && screenLoader.active) {
          delayTimer.restart()
        }
      }
    }

    sourceComponent: PanelWindow {
      id: panel
      screen: modelData

      // === Layer Shell Configuration ===
      WlrLayershell.namespace: "yaqs-notifications"
      WlrLayershell.layer: QsCommons.Settings.data.notifications?.overlayLayer
        ? WlrLayer.Overlay : WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      color: QsCommons.Color.transparent

      // === Full-screen anchors (nixnew pattern) ===
      // This allows notification cards to move freely without clipping
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      // === Position Configuration ===
      readonly property string location: QsCommons.Settings.data.notifications?.location ?? "top_right"
      readonly property bool isTop: location === "top" || location.startsWith("top_")
      readonly property bool isBottom: location === "bottom" || location.startsWith("bottom_")
      readonly property bool isLeft: location.indexOf("_left") >= 0
      readonly property bool isRight: location.indexOf("_right") >= 0
      readonly property bool isCentered: location === "top" || location === "bottom"

      // === Card Dimensions ===
      readonly property real cardWidth: Math.round(360 * QsCommons.Style.uiScaleRatio)
      readonly property real swipeOverflow: Math.round(150 * QsCommons.Style.uiScaleRatio)

      // === Bar-Aware Positioning ===
      function calculateOffset(edge) {
        const barPos = QsCommons.Settings.data.bar?.position ?? "top"
        const isFloating = QsCommons.Settings.data.bar?.floating ?? false
        const base = QsCommons.Style.marginM

        if (barPos === edge) {
          const floatExtra = isFloating
            ? (edge === "top" || edge === "bottom"
              ? QsCommons.Settings.data.bar?.marginVertical ?? 0
              : QsCommons.Settings.data.bar?.marginHorizontal ?? 0) * QsCommons.Style.marginXL
            : 0
          return QsCommons.Style.barHeight + base + floatExtra
        }
        return base
      }

      readonly property real topOffset: calculateOffset("top")
      readonly property real bottomOffset: calculateOffset("bottom")
      readonly property real leftOffset: calculateOffset("left")
      readonly property real rightOffset: calculateOffset("right")

      // === Mask for clickthrough (nixnew pattern) ===
      // Only the notification stack area is interactive
      mask: Region { item: notificationStack }

      // === Service Signal Connection ===
      property var animateConnection: null

      Component.onCompleted: {
        animateConnection = QsServices.NotificationService.animateAndRemove.connect(
          function(notificationId) {
            // Safety check for null notificationStack
            if (!notificationStack || !notificationStack.children) {
              QsServices.NotificationService.dismissActiveNotification(notificationId)
              return
            }
            
            // Find the delegate by notification ID
            for (var i = 0; i < notificationStack.children.length; i++) {
              var child = notificationStack.children[i]
              if (child && child.notificationId === notificationId) {
                if (typeof child.animateOut === "function") {
                  child.animateOut()
                } else {
                  QsServices.NotificationService.dismissActiveNotification(notificationId)
                }
                return
              }
            }
            // Fallback: remove without animation
            QsServices.NotificationService.dismissActiveNotification(notificationId)
          }
        )
      }

      Component.onDestruction: {
        if (animateConnection) {
          QsServices.NotificationService.animateAndRemove.disconnect(animateConnection)
          animateConnection = null
        }
      }

      // === Notification Stack ===
      ColumnLayout {
        id: notificationStack

        // Position based on configured location
        x: {
          if (panel.isCentered) {
            return (panel.width - width) / 2
          } else if (panel.isRight) {
            return panel.width - width - panel.rightOffset
          } else {
            return panel.leftOffset
          }
        }

        y: panel.isTop ? panel.topOffset : undefined

        // For bottom positioning, anchor from bottom
        anchors.bottom: panel.isBottom ? parent.bottom : undefined
        anchors.bottomMargin: panel.isBottom ? panel.bottomOffset : 0

        spacing: QsCommons.Style.marginS
        width: panel.cardWidth + panel.swipeOverflow * 2

        // Animate height changes for smooth stack behavior
        Behavior on implicitHeight {
          enabled: !QsCommons.Settings.data.general?.animationDisabled
          SpringAnimation {
            spring: 2.0
            damping: 0.4
            epsilon: 0.01
          }
        }

        // Stack: newest (index 0) at top, oldest at bottom
        Repeater {
          id: notificationRepeater
          model: notificationModel
          
          delegate: NotificationCard {
            required property int index
            required property var model
            
            notificationId: model.id ?? ""
            notificationData: model
            cardWidth: panel.cardWidth
            swipeOverflow: panel.swipeOverflow
            isTop: panel.isTop
            animationDelay: index * 80
          }
        }
      }
    }
  }
}
