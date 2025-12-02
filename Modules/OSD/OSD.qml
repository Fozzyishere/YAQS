import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Commons" as QsCommons
import "../../Services" as QsServices
import "../../Components" as QsComponents

Variants {
  model: Quickshell.screens.filter(screen => 
    (QsCommons.Settings.data.osd?.monitors?.includes(screen.name) || 
     (QsCommons.Settings.data.osd?.monitors?.length ?? 0) === 0) &&
    (QsCommons.Settings.data.osd?.enabled ?? true)
  )

  delegate: Loader {
    id: root
    required property ShellScreen modelData

    // === Loader State ===
    active: false

    // === OSD State ===
    property string currentOSDType: ""  // "volume", "inputVolume", "brightness"

    // === Volume Properties ===
    readonly property real currentVolume: QsServices.AudioService.volume
    readonly property bool isMuted: QsServices.AudioService.muted
    property bool volumeInitialized: false
    property bool muteInitialized: false

    // === Input Volume Properties ===
    readonly property real currentInputVolume: QsServices.AudioService.inputVolume
    readonly property bool isInputMuted: QsServices.AudioService.inputMuted
    property bool inputAudioInitialized: false

    // === Brightness Properties ===
    property real lastUpdatedBrightness: 0
    readonly property real currentBrightness: lastUpdatedBrightness
    property bool brightnessInitialized: false

    // === Icon Logic ===
    function getIcon() {
      if (currentOSDType === "volume") {
        if (QsServices.AudioService.muted) return "volume-off"
        const vol = QsServices.AudioService.volume
        if (vol <= Number.EPSILON) return "volume"
        if (vol <= 0.5) return "volume-2"
        return "volume"
      }
      if (currentOSDType === "inputVolume") {
        return QsServices.AudioService.inputMuted ? "microphone-off" : "microphone"
      }
      if (currentOSDType === "brightness") {
        return currentBrightness <= 0.5 ? "sun-low" : "sun"
      }
      return ""
    }

    // === Value Logic ===
    function getCurrentValue() {
      if (currentOSDType === "volume") return isMuted ? 0 : currentVolume
      if (currentOSDType === "inputVolume") return isInputMuted ? 0 : currentInputVolume
      if (currentOSDType === "brightness") return currentBrightness
      return 0
    }

    function getDisplayPercentage() {
      if (currentOSDType === "volume") {
        if (isMuted) return "0%"
        return Math.round(Math.min(1.0, currentVolume) * 100) + "%"
      }
      if (currentOSDType === "inputVolume") {
        if (isInputMuted) return "0%"
        return Math.round(Math.min(1.0, currentInputVolume) * 100) + "%"
      }
      if (currentOSDType === "brightness") {
        return Math.round(Math.min(1.0, currentBrightness) * 100) + "%"
      }
      return ""
    }

    // === Color Logic ===
    function getProgressColor() {
      if (currentOSDType === "volume" && isMuted) return QsCommons.Color.mError
      if (currentOSDType === "inputVolume" && isInputMuted) return QsCommons.Color.mError
      return QsCommons.Color.mPrimary
    }

    function getIconColor() {
      if ((currentOSDType === "volume" && isMuted) || 
          (currentOSDType === "inputVolume" && isInputMuted)) {
        return QsCommons.Color.mError
      }
      return QsCommons.Color.mOnSurface
    }

    // === Panel Window ===
    sourceComponent: PanelWindow {
      id: panel
      screen: modelData

      // === Position Calculation ===
      readonly property string location: QsCommons.Settings.data.osd?.location ?? "top_right"
      readonly property bool isTop: location === "top" || location.startsWith("top_")
      readonly property bool isBottom: location === "bottom" || location.startsWith("bottom_")
      readonly property bool isLeft: location.indexOf("_left") >= 0 || location === "left"
      readonly property bool isRight: location.indexOf("_right") >= 0 || location === "right"
      readonly property bool isCentered: location === "top" || location === "bottom"
      readonly property bool verticalMode: location === "left" || location === "right"

      // === Dimensions ===
      readonly property int hWidth: Math.round(320 * QsCommons.Style.uiScaleRatio)
      readonly property int hHeight: Math.round(64 * QsCommons.Style.uiScaleRatio)
      readonly property int vHeight: hWidth
      readonly property int barThickness: {
        const base = Math.max(8, Math.round(8 * QsCommons.Style.uiScaleRatio))
        return (base % 2 === 0) ? base : base + 1
      }

      // === Anchors ===
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

      implicitWidth: verticalMode ? hHeight : hWidth
      implicitHeight: osdItem.height
      color: QsCommons.Color.transparent

      // === Layer Shell ===
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.layer: QsCommons.Settings.data.osd?.overlayLayer 
        ? WlrLayer.Overlay : WlrLayer.Top
      exclusionMode: PanelWindow.ExclusionMode.Ignore

      // === OSD Container ===
      Rectangle {
        id: osdItem

        width: parent.width
        height: panel.verticalMode ? panel.vHeight : Math.round(64 * QsCommons.Style.uiScaleRatio)
        radius: QsCommons.Style.radiusL
        color: QsCommons.Color.mSurface
        border.color: QsCommons.Color.mOutline
        border.width: Math.max(2, QsCommons.Style.borderM)
        visible: false
        opacity: 0
        scale: 0.85

        anchors.horizontalCenter: (!panel.verticalMode && panel.isCentered) 
          ? parent.horizontalCenter : undefined
        anchors.verticalCenter: panel.verticalMode ? parent.verticalCenter : undefined

        // === Animations ===
        Behavior on opacity {
          NumberAnimation {
            duration: QsCommons.Style.animationNormal
            easing.type: Easing.InOutQuad
          }
        }

        Behavior on scale {
          NumberAnimation {
            duration: QsCommons.Style.animationNormal
            easing.type: Easing.InOutQuad
          }
        }

        // === Timers ===
        Timer {
          id: hideTimer
          interval: QsCommons.Settings.data.osd?.autoHideMs ?? 2000
          onTriggered: osdItem.hide()
        }

        Timer {
          id: visibilityTimer
          interval: QsCommons.Style.animationNormal + 50
          onTriggered: {
            osdItem.visible = false
            root.currentOSDType = ""
            root.active = false
          }
        }

        // === Content Loader (Horizontal/Vertical) ===
        Loader {
          anchors.fill: parent
          sourceComponent: panel.verticalMode ? verticalContent : horizontalContent
        }

        // === Horizontal Layout ===
        Component {
          id: horizontalContent
          Item {
            anchors.fill: parent

            RowLayout {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: QsCommons.Style.marginL
              spacing: QsCommons.Style.marginM

              QsComponents.CIcon {
                icon: root.getIcon()
                color: root.getIconColor()
                pointSize: QsCommons.Style.fontSizeXL
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                  ColorAnimation {
                    duration: QsCommons.Style.animationNormal
                    easing.type: Easing.InOutQuad
                  }
                }
              }

              // Progress bar
              Rectangle {
                Layout.fillWidth: true
                height: panel.barThickness
                radius: Math.round(panel.barThickness / 2)
                color: QsCommons.Color.mSurfaceVariant
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * Math.min(1.0, root.getCurrentValue())
                  radius: parent.radius
                  color: root.getProgressColor()

                  Behavior on width {
                    NumberAnimation {
                      duration: QsCommons.Style.animationNormal
                      easing.type: Easing.InOutQuad
                    }
                  }
                  Behavior on color {
                    ColorAnimation {
                      duration: QsCommons.Style.animationNormal
                      easing.type: Easing.InOutQuad
                    }
                  }
                }
              }

              // Percentage
              QsComponents.CText {
                text: root.getDisplayPercentage()
                color: QsCommons.Color.mOnSurface
                family: QsCommons.Settings.data.ui?.fontFixed ?? "monospace"
                pointSize: QsCommons.Style.fontSizeS
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Math.round(50 * QsCommons.Style.uiScaleRatio)
              }
            }
          }
        }

        // === Vertical Layout ===
        Component {
          id: verticalContent
          Item {
            anchors.fill: parent

            ColumnLayout {
              anchors.fill: parent
              anchors.topMargin: Math.max(osdItem.radius, QsCommons.Style.marginL)
              anchors.bottomMargin: Math.max(osdItem.radius, QsCommons.Style.marginL)
              spacing: QsCommons.Style.marginS

              // Percentage at top
              QsComponents.CText {
                text: root.getDisplayPercentage()
                color: QsCommons.Color.mOnSurface
                family: QsCommons.Settings.data.ui?.fontFixed ?? "monospace"
                pointSize: QsCommons.Style.fontSizeS
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
              }

              // Vertical progress bar
              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: panel.barThickness
                  radius: Math.round(panel.barThickness / 2)
                  color: QsCommons.Color.mSurfaceVariant

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * Math.min(1.0, root.getCurrentValue())
                    radius: parent.radius
                    color: root.getProgressColor()

                    Behavior on height {
                      NumberAnimation {
                        duration: QsCommons.Style.animationNormal
                        easing.type: Easing.InOutQuad
                      }
                    }
                    Behavior on color {
                      ColorAnimation {
                        duration: QsCommons.Style.animationNormal
                        easing.type: Easing.InOutQuad
                      }
                    }
                  }
                }
              }

              // Icon at bottom
              QsComponents.CIcon {
                icon: root.getIcon()
                color: root.getIconColor()
                pointSize: QsCommons.Style.fontSizeL
                Layout.alignment: Qt.AlignHCenter

                Behavior on color {
                  ColorAnimation {
                    duration: QsCommons.Style.animationNormal
                    easing.type: Easing.InOutQuad
                  }
                }
              }
            }
          }
        }

        // === Functions ===
        function show() {
          hideTimer.stop()
          visibilityTimer.stop()
          visible = true
          Qt.callLater(() => {
            opacity = 1
            scale = 1.0
          })
          hideTimer.start()
        }

        function hide() {
          hideTimer.stop()
          visibilityTimer.stop()
          opacity = 0
          scale = 0.85
          visibilityTimer.start()
        }

        function hideImmediately() {
          hideTimer.stop()
          visibilityTimer.stop()
          opacity = 0
          scale = 0.85
          visible = false
          root.currentOSDType = ""
          root.active = false
        }
      }

      function showOSD() {
        osdItem.show()
      }
    }

    // === Audio Service Connections ===
    Connections {
      target: QsServices.AudioService

      function onVolumeChanged() {
        if (volumeInitialized) showOSD("volume")
      }

      function onMutedChanged() {
        if (muteInitialized) showOSD("volume")
      }

      function onInputVolumeChanged() {
        if (inputAudioInitialized) showOSD("inputVolume")
      }

      function onInputMutedChanged() {
        if (inputAudioInitialized) showOSD("inputVolume")
      }
    }

    // === Delayed Initialization ===
    Timer {
      id: initTimer
      interval: 500
      running: true
      onTriggered: {
        volumeInitialized = true
        muteInitialized = true
        inputAudioInitialized = true
        connectBrightnessMonitors()
      }
    }

    // === Brightness Service Connections ===
    Connections {
      target: QsServices.BrightnessService
      function onMonitorsChanged() {
        connectBrightnessMonitors()
      }
    }

    function connectBrightnessMonitors() {
      for (var i = 0; i < QsServices.BrightnessService.monitors.length; i++) {
        let monitor = QsServices.BrightnessService.monitors[i]
        monitor.brightnessUpdated.disconnect(onBrightnessChanged)
        monitor.brightnessUpdated.connect(onBrightnessChanged)
      }
    }

    function onBrightnessChanged(newBrightness) {
      root.lastUpdatedBrightness = newBrightness

      if (!brightnessInitialized) {
        brightnessInitialized = true
        return
      }

      showOSD("brightness")
    }

    function showOSD(type) {
      currentOSDType = type

      if (!root.active) {
        root.active = true
      }

      if (root.item) {
        root.item.showOSD()
      } else {
        Qt.callLater(() => {
          if (root.item) root.item.showOSD()
        })
      }
    }

    function hideOSD() {
      if (root.item && root.item.osdItem) {
        root.item.osdItem.hideImmediately()
      } else if (root.active) {
        root.active = false
      }
    }
  }
}
