import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property string label: ""
  property string description: ""
  property bool checked: false
  property string group: ""  // For radio button grouping context

  // === Signals ===
  signal toggled(bool checked)

  // === Layout ===
  Layout.fillWidth: true
  spacing: QsCommons.Style.marginM

  // === Child Components ===
  QsComponents.CLabel {
    label: root.label
    description: root.description
    visible: root.label !== "" || root.description !== ""
  }

  Item {
    Layout.fillWidth: true
  }  // Spacer

  Rectangle {
    id: radioCircle

    implicitWidth: QsCommons.Style.baseWidgetSize * 0.7
    implicitHeight: QsCommons.Style.baseWidgetSize * 0.7

    // Outer circle (keep circular)
    radius: width / 2

    color: QsCommons.Color.mSurface
    border.color: root.checked ? QsCommons.Color.mPrimary : QsCommons.Color.mOutline
    border.width: QsCommons.Style.borderS

    Behavior on border.color {
      ColorAnimation {
        duration: QsCommons.Style.animationFast
      }
    }

    // Inner dot (when checked)
    Rectangle {
      visible: root.checked
      anchors.centerIn: parent
      width: parent.width * 0.5
      height: parent.height * 0.5
      radius: width / 2  // Circular dot
      color: QsCommons.Color.mPrimary
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (!root.checked) {
          root.checked = true
          root.toggled(true)
        }
      }
    }
  }
}
