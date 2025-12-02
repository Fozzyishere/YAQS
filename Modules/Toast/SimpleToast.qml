import QtQuick
import QtQuick.Layouts
import "../../Commons" as QsCommons
import "../../Components" as QsComponents

Rectangle {
  id: root

  // === Properties ===
  property int toastIndex: 0
  property string toastMessage: ""
  property string toastDescription: ""
  property string toastType: "notice"  // "notice", "warning", "error"

  // === Signal ===
  signal dismissRequested

  // === Animation State ===
  property real scaleValue: 0.8
  property real opacityValue: 0.0
  property real slideOffset: 0
  property bool isRemoving: false
  readonly property int animationDelay: toastIndex * 80  // Staggered entry

  // === Sizing ===
  implicitWidth: parent?.width ?? Math.round(420 * QsCommons.Style.uiScaleRatio)
  implicitHeight: Math.round(contentLayout.implicitHeight + QsCommons.Style.marginL * 2)
  radius: QsCommons.Style.radiusL
  color: QsCommons.Color.mSurface

  // Apply animations
  scale: scaleValue
  opacity: opacityValue
  transform: Translate { y: slideOffset }

  // === Type-Based Border Color ===
  border.color: {
    switch (toastType) {
      case "warning": return QsCommons.Color.mPrimary
      case "error": return QsCommons.Color.mError
      default: return QsCommons.Color.mOutline
    }
  }
  border.width: Math.max(2, QsCommons.Style.borderM)

  // === Animation Behaviors ===
  Behavior on scaleValue {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    NumberAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  Behavior on opacityValue {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    NumberAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  Behavior on slideOffset {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    NumberAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  // === Entry Animation ===
  Component.onCompleted: {
    if (QsCommons.Settings.data.general?.animationDisabled) {
      scaleValue = 1.0
      opacityValue = 1.0
      slideOffset = 0
    } else {
      // Start from animated state
      scaleValue = 0.8
      opacityValue = 0.0
      slideOffset = Math.round(-30 * QsCommons.Style.uiScaleRatio)
      // Staggered animation start
      entryDelayTimer.interval = animationDelay
      entryDelayTimer.start()
    }
  }

  Timer {
    id: entryDelayTimer
    interval: 0
    repeat: false
    onTriggered: {
      scaleValue = 1.0
      opacityValue = 1.0
      slideOffset = 0
    }
  }

  // === Close Button (positioned absolutely) ===
  QsComponents.CIconButton {
    id: closeButton
    icon: "x"
    tooltipText: "Dismiss"
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: QsCommons.Style.marginS
    anchors.rightMargin: QsCommons.Style.marginS
    baseSize: Math.round(QsCommons.Style.baseWidgetSize * 0.5)
    onClicked: root.dismissRequested()
    z: 10
  }

  // === Content Layout ===
  RowLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: QsCommons.Style.marginL
    anchors.rightMargin: QsCommons.Style.marginL + closeButton.width
    spacing: QsCommons.Style.marginL

    // Type icon
    QsComponents.CIcon {
      icon: {
        switch (root.toastType) {
          case "warning": return "alert-triangle"
          case "error": return "alert-circle"
          default: return "info-circle"
        }
      }
      color: {
        switch (root.toastType) {
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
        text: root.toastMessage
        color: QsCommons.Color.mOnSurface
        pointSize: QsCommons.Style.fontSizeL
        font.weight: QsCommons.Style.fontWeightBold
        wrapMode: Text.WordWrap
        visible: text.length > 0
      }

      QsComponents.CText {
        Layout.fillWidth: true
        text: root.toastDescription
        color: QsCommons.Color.mOnSurface
        pointSize: QsCommons.Style.fontSizeM
        wrapMode: Text.WordWrap
        visible: text.length > 0
      }
    }
  }

  // === Click to Dismiss ===
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    onClicked: root.dismissRequested()
    cursorShape: Qt.PointingHandCursor
    z: -1  // Behind content so close button works
  }
}
