import QtQuick
import Quickshell
import Quickshell.Widgets
import "../Commons" as QsCommons
import "../Services" as QsServices

Rectangle {
  id: root

  // === Public Properties ===
  property real baseSize: QsCommons.Style.baseWidgetSize
  property bool shouldApplyUiScale: true
  property string icon
  property string tooltipText
  property string tooltipDirection: "auto"
  property string density: ""
  property bool isEnabled: true
  property bool shouldAllowClickWhenDisabled: false
  property color colorBg: QsCommons.Color.transparent
  property color colorFg: QsCommons.Color.mOnSurfaceVariant
  property color colorBgHover: Qt.alpha(QsCommons.Color.mOnSurfaceVariant, QsCommons.Style.opacityHover)
  property color colorFgHover: QsCommons.Color.mOnSurfaceVariant
  property bool hasBorder: false

  // === Signals ===
  signal entered
  signal exited
  signal clicked
  signal rightClicked
  signal middleClicked

  // === Private State ===
  property bool _isHovering: false

  // === Dimensions ===
  implicitWidth: shouldApplyUiScale ? Math.round(baseSize * QsCommons.Style.uiScaleRatio) : Math.round(baseSize)
  implicitHeight: shouldApplyUiScale ? Math.round(baseSize * QsCommons.Style.uiScaleRatio) : Math.round(baseSize)

  // === Appearance ===
  opacity: root.isEnabled ? QsCommons.Style.opacityFull : QsCommons.Style.opacityDisabled
  color: root.isEnabled && root._isHovering ? colorBgHover : colorBg
  radius: width / 2
  border.width: hasBorder ? QsCommons.Style.borderS : 0
  border.color: hasBorder ? QsCommons.Color.mOutline : "transparent"

  Behavior on color {
    ColorAnimation {
      duration: QsCommons.Style.animationFast
      easing.type: Easing.OutCubic
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
        return Math.max(1, root.width * 0.55)
      }
    }
    shouldApplyUiScale: false
    color: root.isEnabled ? colorFg : QsCommons.Color.mOnSurfaceVariant
    x: (root.width - width) / 2
    y: (root.height - height) / 2 + (height - contentHeight) / 2

    Behavior on color {
      ColorAnimation {
        duration: QsCommons.Style.animationFast
        easing.type: Easing.OutCubic
      }
    }
  }

  MouseArea {
    id: mouseArea
    enabled: true
    anchors.fill: parent
    cursorShape: root.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true

    onEntered: {
      root._isHovering = root.isEnabled
      if (tooltipText) {
        QsServices.TooltipService.show(Screen, root, tooltipText, tooltipDirection)
      }
      root.entered()
    }

    onExited: {
      root._isHovering = false
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
      root.exited()
    }

    onClicked: function (mouse) {
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
      if (!root.isEnabled && !shouldAllowClickWhenDisabled) {
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

    onCanceled: {
      root._isHovering = false
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
    }
  }
}
