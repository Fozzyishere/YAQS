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
  property color hoverColor: QsCommons.Color.mTertiary
  property bool enabled: true
  property real fontSize: QsCommons.Style.fontSizeM
  property int fontWeight: QsCommons.Style.fontWeightBold
  property real iconSize: QsCommons.Style.fontSizeL
  property bool outlined: false
  property int horizontalAlignment: Qt.AlignHCenter

  // === Signals ===
  signal clicked
  signal rightClicked
  signal middleClicked
  signal entered
  signal exited

  // === Private State ===
  property bool hovered: false

  // === Dimensions ===
  implicitWidth: contentRow.implicitWidth + (QsCommons.Style.marginM * 2)
  implicitHeight: Math.max(QsCommons.Style.baseWidgetSize, contentRow.implicitHeight + (QsCommons.Style.marginM))

  // === Appearance ===
  radius: QsCommons.Style.radiusS
  color: {
    if (!enabled)
      return outlined ? QsCommons.Color.transparent : Qt.lighter(QsCommons.Color.mSurfaceVariant, 1.2)
    if (hovered)
      return hoverColor
    return outlined ? QsCommons.Color.transparent : backgroundColor
  }

  border.width: QsCommons.Style.borderS
  border.color: {
    if (!enabled)
      return QsCommons.Color.mOutline
    if (hovered)
      return backgroundColor
    return outlined ? backgroundColor : QsCommons.Color.mOutline
  }

  opacity: enabled ? 1.0 : 0.6

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
      // Icon component (optional)
      Layout.alignment: Qt.AlignVCenter
      visible: root.icon !== ""
      icon: root.icon
      pointSize: root.iconSize
      color: {
        if (!root.enabled)
          return QsCommons.Color.mOnSurfaceVariant
        if (root.outlined) {
          if (root.hovered)
            return root.textColor
          return root.backgroundColor
        }
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
      // Text component
      Layout.alignment: Qt.AlignVCenter
      visible: root.text !== ""
      text: root.text
      pointSize: root.fontSize
      font.weight: root.fontWeight
      color: {
        if (!root.enabled)
          return QsCommons.Color.mOnSurfaceVariant
        if (root.outlined) {
          if (root.hovered)
            return root.textColor
          return root.backgroundColor
        }
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

  // === Mouse Interaction ===
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onEntered: {
      root.hovered = true
      root.entered()
      if (tooltipText) {
        QsServices.TooltipService.show(Screen, root, root.tooltipText)
      }
    }
    onExited: {
      root.hovered = false
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
                 } else if (mouse.button == Qt.RightButton) {
                   root.rightClicked()
                 } else if (mouse.button == Qt.MiddleButton) {
                   root.middleClicked()
                 }
               }

    onCanceled: {
      root.hovered = false
      if (tooltipText) {
        QsServices.TooltipService.hide()
      }
    }
  }
}
