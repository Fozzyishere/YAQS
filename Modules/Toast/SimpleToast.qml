import QtQuick
import QtQuick.Layouts
import "../../Commons" as QsCommons
import "../../Components" as QsComponents

Rectangle {
  id: root

  // === Properties ===
  property string message: ""
  property string description: ""
  property string type: "notice"  // "notice", "warning", "error"
  property int duration: 3000
  readonly property real initialScale: 0.7

  // === Signal ===
  signal hidden

  // === Sizing ===
  width: parent.width
  height: Math.round(contentLayout.implicitHeight + QsCommons.Style.marginL * 2)
  radius: QsCommons.Style.radiusL
  visible: false
  opacity: 0
  scale: initialScale
  color: QsCommons.Color.mSurface

  // === Type-Based Border Color ===
  border.color: {
    switch (type) {
      case "warning": return QsCommons.Color.mPrimary
      case "error": return QsCommons.Color.mError
      default: return QsCommons.Color.mOutline
    }
  }
  border.width: Math.max(2, QsCommons.Style.borderM)

  // === Animations ===
  Behavior on opacity {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    NumberAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  Behavior on scale {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    NumberAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  // === Auto-Hide Timer ===
  Timer {
    id: hideTimer
    interval: root.duration
    onTriggered: root.hide()
  }

  // === Hide Animation Completion Timer ===
  Timer {
    id: hideAnimation
    interval: QsCommons.Style.animationFast
    onTriggered: {
      root.visible = false
      root.hidden()
    }
  }

  // === Cleanup on Destruction ===
  Component.onDestruction: {
    hideTimer.stop()
    hideAnimation.stop()
  }

  // === Content Layout ===
  RowLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: QsCommons.Style.marginL
    spacing: QsCommons.Style.marginL

    // Type icon
    QsComponents.CIcon {
      icon: {
        switch (root.type) {
          case "warning": return "alert-triangle"
          case "error": return "alert-circle"
          default: return "info-circle"
        }
      }
      color: {
        switch (root.type) {
          case "warning": return QsCommons.Color.mPrimary
          case "error": return QsCommons.Color.mError
          default: return QsCommons.Color.mOnSurface
        }
      }
      pointSize: QsCommons.Style.fontSizeXXL * 1.5
      Layout.alignment: Qt.AlignVCenter
    }

    // Message and description
    ColumnLayout {
      spacing: QsCommons.Style.marginXXS
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter

      QsComponents.CText {
        Layout.fillWidth: true
        text: root.message
        color: QsCommons.Color.mOnSurface
        pointSize: QsCommons.Style.fontSizeL
        font.weight: QsCommons.Style.fontWeightBold
        wrapMode: Text.WordWrap
        visible: text.length > 0
      }

      QsComponents.CText {
        Layout.fillWidth: true
        text: root.description
        color: QsCommons.Color.mOnSurface
        pointSize: QsCommons.Style.fontSizeM
        wrapMode: Text.WordWrap
        visible: text.length > 0
      }
    }
  }

  // === Click Anywhere to Dismiss ===
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    onClicked: root.hide()
    cursorShape: Qt.PointingHandCursor
  }

  // === Functions ===
  function show(msg, desc, msgType, msgDuration) {
    // Stop all timers first
    hideTimer.stop()
    hideAnimation.stop()

    message = msg
    description = desc || ""
    type = msgType || "notice"
    duration = msgDuration || 3000

    visible = true
    opacity = 1
    scale = 1.0

    hideTimer.restart()
  }

  function hide() {
    hideTimer.stop()
    opacity = 0
    scale = initialScale
    hideAnimation.restart()
  }

  function hideImmediately() {
    hideTimer.stop()
    hideAnimation.stop()
    opacity = 0
    scale = initialScale
    visible = false
    hidden()
  }
}
