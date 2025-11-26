import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Services" as QsServices

Rectangle {
  id: root

  // === Public Properties ===
  property string text: ""
  property string icon: ""
  property string tooltipText
  property color backgroundColor: QsCommons.Color.mPrimary
  property color textColor: QsCommons.Color.mOnPrimary
  property bool isEnabled: true
  property real fontSize: QsCommons.Style.fontSizeM
  property int fontWeight: QsCommons.Style.fontWeightMedium
  property real iconSize: QsCommons.Style.fontSizeL
  property bool isOutlined: false
  property bool isTonal: false
  property int horizontalAlignment: Qt.AlignHCenter

  // === Signals ===
  signal clicked
  signal rightClicked
  signal middleClicked
  signal entered
  signal exited

  // === Private State ===
  property bool _isHovered: false

  // === Dimensions ===
  implicitWidth: contentRow.implicitWidth + (QsCommons.Style.marginS * 2)
  implicitHeight: Math.max(QsCommons.Style.baseWidgetSize, contentRow.implicitHeight + (QsCommons.Style.marginS))

  // === Appearance ===
  radius: QsCommons.Style.radiusS

  color: {
    if (!isEnabled) {
      return isOutlined ? QsCommons.Color.transparent : Qt.alpha(QsCommons.Color.mOnSurface, 0.12)
    }
    if (isTonal) {
      return _isHovered ? Qt.lighter(QsCommons.Color.mSecondaryContainer, 1.08) : QsCommons.Color.mSecondaryContainer
    }
    if (isOutlined) {
      return _isHovered ? Qt.alpha(QsCommons.Color.mPrimary, QsCommons.Style.opacityHover) : QsCommons.Color.transparent
    }
    return _isHovered ? Qt.lighter(backgroundColor, 1.08) : backgroundColor
  }

  border.width: isOutlined ? QsCommons.Style.borderS : 0
  border.color: {
    if (!isEnabled) return QsCommons.Color.mOutline
    return isOutlined ? QsCommons.Color.mOutline : "transparent"
  }

  opacity: isEnabled ? QsCommons.Style.opacityFull : QsCommons.Style.opacityDisabled

  Behavior on color {
    ColorAnimation {
      duration: QsCommons.Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  Behavior on border.color {
    ColorAnimation {
      duration: QsCommons.Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  // === Content ===
  RowLayout {
    id: contentRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: root.horizontalAlignment === Qt.AlignLeft ? parent.left : undefined
    anchors.horizontalCenter: root.horizontalAlignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
    anchors.leftMargin: root.horizontalAlignment === Qt.AlignLeft ? QsCommons.Style.marginM : 0
    spacing: QsCommons.Style.marginXS

    CIcon {
      Layout.alignment: Qt.AlignVCenter
      visible: root.icon !== ""
      icon: root.icon
      pointSize: root.iconSize
      color: {
        if (!root.isEnabled) return QsCommons.Color.mOnSurfaceVariant
        if (root.isTonal) return QsCommons.Color.mOnSecondaryContainer
        if (root.isOutlined) return QsCommons.Color.mPrimary
        return root.textColor
      }

      Behavior on color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    CText {
      Layout.alignment: Qt.AlignVCenter
      visible: root.text !== ""
      text: root.text
      pointSize: root.fontSize
      font.weight: root.fontWeight
      color: {
        if (!root.isEnabled) return QsCommons.Color.mOnSurfaceVariant
        if (root.isTonal) return QsCommons.Color.mOnSecondaryContainer
        if (root.isOutlined) return QsCommons.Color.mPrimary
        return root.textColor
      }

      Behavior on color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.isEnabled
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: root.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onEntered: {
      root._isHovered = true
      root.entered()
      if (tooltipText) {
        QsServices.TooltipService.show(Screen, root, root.tooltipText)
      }
    }

    onExited: {
      root._isHovered = false
      root.exited()
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
    }

    onPressed: mouse => {
      if (tooltipText) {
        QsServices.TooltipService.hide()
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
      root._isHovered = false
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
    }
  }
}
