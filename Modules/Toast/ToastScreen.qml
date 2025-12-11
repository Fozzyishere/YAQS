import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Commons" as QsCommons
import "../../Services" as QsServices

Item {
  id: root

  required property ShellScreen screen

  // === Local Queue (bounded to prevent memory issues) ===
  property var messageQueue: []
  property int maxQueueSize: 10
  property bool isShowingToast: false

  // === ToastService Connection ===
  Connections {
    target: QsServices.ToastService

    function onNotify(message, description, type, duration) {
      root.enqueueToast({
        "message": message,
        "description": description,
        "type": type,
        "duration": duration
      })
    }
  }

  // === Cleanup on Destruction ===
  Component.onDestruction: {
    messageQueue = []
    isShowingToast = false
    hideTimer.stop()
    quickSwitchTimer.stop()
  }

  // === Queue Logic ===
  function enqueueToast(toastData) {
    QsCommons.Logger.i("ToastScreen", "Queuing", toastData.type + ":", toastData.message)

    // Bounded queue to prevent unbounded memory growth
    if (messageQueue.length >= maxQueueSize) {
      QsCommons.Logger.i("ToastScreen", "Queue full, dropping oldest toast")
      messageQueue.shift()
    }

    // Replace mode: clear queue and show new toast immediately
    messageQueue = []
    messageQueue.push(toastData)

    if (isShowingToast) {
      // Hide current toast immediately
      if (windowLoader.item) {
        hideTimer.stop()
        windowLoader.item.hideToast()
      }
      isShowingToast = false
      quickSwitchTimer.restart()
    } else {
      processQueue()
    }
  }

  Timer {
    id: quickSwitchTimer
    interval: 50  // Brief delay for smooth transition
    onTriggered: root.processQueue()
  }

  function processQueue() {
    if (messageQueue.length === 0 || isShowingToast) return

    var data = messageQueue.shift()
    isShowingToast = true

    // Store toast data for when loader is ready
    windowLoader.pendingToast = data

    // Activate the loader
    windowLoader.active = true
  }

  function onToastHidden() {
    isShowingToast = false

    // Deactivate loader to free memory
    windowLoader.active = false

    // Small delay before processing next toast
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: root.processQueue()
  }

  // === Loader Pattern ===
  Loader {
    id: windowLoader
    active: false

    // Store pending toast data
    property var pendingToast: null

    onStatusChanged: {
      if (status === Loader.Ready && pendingToast !== null) {
        item.showToast(pendingToast.message, pendingToast.description,
                       pendingToast.type, pendingToast.duration)
        pendingToast = null
      }
    }

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
      implicitHeight: toastItem.height
      color: QsCommons.Color.transparent

      // === Layer Shell Configuration ===
      WlrLayershell.layer: QsCommons.Settings.data.notifications?.overlayLayer
        ? WlrLayer.Overlay : WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: PanelWindow.ExclusionMode.Ignore

      function showToast(message, description, type, duration) {
        toastItem.show(message, description, type, duration)
      }

      function hideToast() {
        toastItem.hideImmediately()
      }

      SimpleToast {
        id: toastItem
        anchors.horizontalCenter: parent.horizontalCenter
        onHidden: root.onToastHidden()
      }
    }
  }
}
