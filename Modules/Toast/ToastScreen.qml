import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Commons" as QsCommons
import "../../Services" as QsServices

Item {
  id: root

  required property ShellScreen screen

  // === Toast List Model Reference ===
  property ListModel toastModel: QsServices.ToastService.toastList

  // === Loader Active State ===
  // Active when there are toasts OR delay timer is running (for exit animations)
  property bool hasToasts: toastModel.count > 0

  // Keep loader active briefly after last toast to allow animations to complete
  Timer {
    id: delayTimer
    interval: QsCommons.Style.animationSlow + 100
    repeat: false
  }

  Connections {
    target: toastModel
    function onCountChanged() {
      if (toastModel.count === 0 && windowLoader.active) {
        delayTimer.restart()
      }
    }
  }

  // === Loader Pattern (Memory Efficient) ===
  Loader {
    id: windowLoader
    active: root.hasToasts || delayTimer.running

    sourceComponent: PanelWindow {
      id: panel
      screen: root.screen

      // === Position Calculation ===
      readonly property string location: QsCommons.Settings.data.notifications?.location ?? "top_right"
      readonly property bool isTop: location === "top" || location.startsWith("top_")
      readonly property bool isBottom: location === "bottom" || location.startsWith("bottom_")
      readonly property bool isLeft: location.indexOf("_left") >= 0
      readonly property bool isRight: location.indexOf("_right") >= 0
      readonly property bool isCentered: location === "top" || location === "bottom"

      anchors.top: isTop
      anchors.bottom: isBottom
      anchors.left: isLeft
      anchors.right: isRight

      // === Bar-Aware Margins ===
      margins.top: {
        if (!anchors.top) return 0
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "top") {
          var floatExtra = QsCommons.Settings.data.bar.floating 
            ? QsCommons.Settings.data.bar.marginVertical * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtra
        }
        return base
      }

      margins.bottom: {
        if (!anchors.bottom) return 0
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "bottom") {
          var floatExtra = QsCommons.Settings.data.bar.floating 
            ? QsCommons.Settings.data.bar.marginVertical * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtra
        }
        return base
      }

      margins.left: {
        if (!anchors.left) return 0
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "left") {
          var floatExtra = QsCommons.Settings.data.bar.floating 
            ? QsCommons.Settings.data.bar.marginHorizontal * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtra
        }
        return base
      }

      margins.right: {
        if (!anchors.right) return 0
        var base = QsCommons.Style.marginM
        if (QsCommons.Settings.data.bar.position === "right") {
          var floatExtra = QsCommons.Settings.data.bar.floating 
            ? QsCommons.Settings.data.bar.marginHorizontal * QsCommons.Style.marginXL : 0
          return QsCommons.Style.barHeight + base + floatExtra
        }
        return base
      }

      implicitWidth: Math.round(420 * QsCommons.Style.uiScaleRatio)
      implicitHeight: toastStack.implicitHeight
      color: QsCommons.Color.transparent

      // === Layer Shell Configuration ===
      WlrLayershell.layer: QsCommons.Settings.data.notifications?.overlayLayer 
        ? WlrLayer.Overlay : WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: PanelWindow.ExclusionMode.Ignore

      // === Toast Stack Container ===
      ColumnLayout {
        id: toastStack
        anchors.top: panel.isTop ? parent.top : undefined
        anchors.bottom: panel.isBottom ? parent.bottom : undefined
        anchors.left: panel.isLeft ? parent.left : undefined
        anchors.right: panel.isRight ? parent.right : undefined
        anchors.horizontalCenter: panel.isCentered ? parent.horizontalCenter : undefined
        spacing: QsCommons.Style.marginS
        width: parent.width

        // Animate height changes smoothly
        Behavior on implicitHeight {
          enabled: !QsCommons.Settings.data.general?.animationDisabled
          NumberAnimation {
            duration: QsCommons.Style.animationNormal
            easing.type: Easing.OutCubic
          }
        }

        // === Stacked Toasts (oldest at top, newest at bottom) ===
        Repeater {
          model: root.toastModel

          delegate: SimpleToast {
            required property int index
            required property string toastId
            required property string message
            required property string description
            required property string type

            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight

            toastIndex: index
            toastMessage: message
            toastDescription: description
            toastType: type

            onDismissRequested: QsServices.ToastService.dismissToast(toastId)
          }
        }
      }
    }
  }
}
