import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property string label: ""
  property string description: ""
  property bool checked: false
  property bool hovering: false
  property color activeColor: QsCommons.Color.mPrimary
  property color activeOnColor: QsCommons.Color.mOnPrimary

  // === Sizing ===
  // baseSize controls overall checkbox scale
  property real baseSize: QsCommons.Style.baseWidgetSize * 0.45 * QsCommons.Style.uiScaleRatio

  // Local dimensions
  readonly property real boxSize: Math.round(baseSize)
  readonly property real boxRadius: Math.round(baseSize * 0.11)
  readonly property real iconSize: Math.round(baseSize * 0.67)

  // === Signals ===
  signal toggled(bool checked)
  signal entered
  signal exited

  Layout.fillWidth: true

  QsComponents.CLabel {
    label: root.label
    description: root.description
    visible: root.label !== "" || root.description !== ""
  }

  // Spacer to push the checkbox to the far right
  Item {
    Layout.fillWidth: true
  }

  Rectangle {
    id: box

    // Checkbox dimensions (derived from baseSize)
    implicitWidth: root.boxSize
    implicitHeight: root.boxSize
    radius: root.boxRadius
    
    color: root.checked ? root.activeColor : QsCommons.Color.transparent
    // Border on unchecked state only
    border.color: QsCommons.Color.mOutline
    border.width: root.checked ? QsCommons.Style.borderNone : QsCommons.Style.borderM

    Behavior on color {
      ColorAnimation {
        duration: QsCommons.Style.animationFast
      }
    }

    Behavior on border.width {
      NumberAnimation {
        duration: QsCommons.Style.animationFast
      }
    }

    QsComponents.CIcon {
      visible: root.checked
      anchors.centerIn: parent
      icon: "check"
      color: root.activeOnColor
      pointSize: root.iconSize
      shouldApplyUiScale: false  // Already scaled via baseSize
    } 

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      
      onEntered: {
        hovering = true
        root.entered()
      }
      
      onExited: {
        hovering = false
        root.exited()
      }
      
      onClicked: root.toggled(!root.checked)
    }
  }
}
