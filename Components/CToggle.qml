import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property bool enabled: true
  property bool checked: false
  property bool hovering: false
  property int baseSize: Math.round(QsCommons.Style.baseWidgetSize * 0.8 * QsCommons.Style.uiScaleRatio)

  signal toggled(bool checked)
  signal entered
  signal exited

  Layout.fillWidth: true
  opacity: enabled ? 1.0 : 0.6

  QsComponents.CLabel {
    label: root.label
    description: root.description
  }

  Rectangle {
    id: switcher

    implicitWidth: Math.round(root.baseSize * 0.85) * 2
    implicitHeight: Math.round(root.baseSize * 0.5) * 2
    radius: QsCommons.Style.radiusXS
    
    color: root.checked ? QsCommons.Color.mPrimary : QsCommons.Color.mSurface
    border.color: QsCommons.Color.mOutline
    border.width: QsCommons.Style.borderS

    Behavior on color {
      ColorAnimation {
        duration: QsCommons.Style.animationFast
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: QsCommons.Style.animationFast
      }
    }

    Rectangle {
      implicitWidth: Math.round(root.baseSize * 0.4) * 2
      implicitHeight: Math.round(root.baseSize * 0.4) * 2
      radius: QsCommons.Style.radiusXXS
      
      color: root.checked ? QsCommons.Color.mOnPrimary : QsCommons.Color.mPrimary
      border.color: root.checked ? QsCommons.Color.mSurface : QsCommons.Color.mSurface
      border.width: QsCommons.Style.borderM
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: 0
      x: root.checked ? switcher.width - width - 3 : 3

      Behavior on x {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      
      onEntered: {
        if (!enabled)
          return
        hovering = true
        root.entered()
      }
      
      onExited: {
        if (!enabled)
          return
        hovering = false
        root.exited()
      }
      
      onClicked: {
        if (!enabled)
          return
        root.toggled(!root.checked)
      }
    }
  }
}
