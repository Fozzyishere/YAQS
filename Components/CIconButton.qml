import QtQuick
import Quickshell
import Quickshell.Widgets
import "../Commons" as QsCommons
import "../Services" as QsServices

Rectangle {
  id: root

  // === Public Properties ===
  property real baseSize: QsCommons.Style.baseWidgetSize
  property bool applyUiScale: true
  property string icon
  property string tooltipText
  property string tooltipDirection: "auto"
  property string density: ""
  property bool enabled: true
  property bool allowClickWhenDisabled: false
  property bool hovering: false
  property color colorBg: QsCommons.Color.mSurfaceVariant
  property color colorFg: QsCommons.Color.mPrimary
  property color colorBgHover: QsCommons.Color.mTertiary
  property color colorFgHover: QsCommons.Color.mOnTertiary
  property color colorBorder: QsCommons.Color.mOutline
  property color colorBorderHover: QsCommons.Color.mOutline

  // === Signals ===
  signal entered
  signal exited
  signal clicked
  signal rightClicked
  signal middleClicked

  // === Dimensions ===
  implicitWidth: applyUiScale ? Math.round(baseSize * QsCommons.Style.uiScaleRatio) : Math.round(baseSize)
  implicitHeight: applyUiScale ? Math.round(baseSize * QsCommons.Style.uiScaleRatio) : Math.round(baseSize)

  // === Appearance ===
  opacity: root.enabled ? QsCommons.Style.opacityFull : QsCommons.Style.opacityMedium
  color: root.enabled && root.hovering ? colorBgHover : colorBg

  radius: QsCommons.Style.radiusXS

  border.color: root.enabled && root.hovering ? colorBorderHover : colorBorder
  border.width: QsCommons.Style.borderS

  Behavior on color {
    ColorAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.InOutQuad
    }
  }

  // === Child Components ===
  CIcon {
    icon: root.icon
    pointSize: {
      switch (root.density) {
      case "compact":
        return Math.max(1, root.width * 0.65)
      default:
        return Math.max(1, root.width * 0.48)
      }
    }
    applyUiScale: root.applyUiScale
    color: root.enabled && root.hovering ? colorFgHover : colorFg
    x: (root.width - width) / 2  // Center horizontally
    y: (root.height - height) / 2 + (height - contentHeight) / 2  // Center vertically (font metrics aware)

    Behavior on color {
      ColorAnimation {
        duration: QsCommons.Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
  }

  // === Mouse Interaction ===
  MouseArea {
    enabled: true  // Always enabled for hover/tooltip even when button disabled
    anchors.fill: parent
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    onEntered: {
      hovering = root.enabled ? true : false
      if (tooltipText) {
        QsServices.TooltipService.show(Screen, parent, tooltipText, tooltipDirection)
      }
      root.entered()
    }
    onExited: {
      hovering = false
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
      root.exited()
    }
    onClicked: function (mouse) {
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
      if (!root.enabled && !allowClickWhenDisabled) {
        return
      }
      if (mouse.button === Qt.LeftButton) {
        root.clicked()
      } else if (mouse.button === Qt.RightButton) {
        root.rightClicked()
      } else if (mouse.button === Qt.MiddleButton) {
        root.middleClicked()
      }
    }
  }
}
