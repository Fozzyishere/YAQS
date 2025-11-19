import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // Public API
  property string label: ""
  property string description: ""
  property bool checked: false
  property bool hovering: false
  property color activeColor: QsCommons.Color.mPrimary
  property color activeOnColor: QsCommons.Color.mOnPrimary
  property int baseSize: QsCommons.Style.baseWidgetSize * 0.7

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

    implicitWidth: Math.round(root.baseSize)
    implicitHeight: Math.round(root.baseSize)
    radius: QsCommons.Style.radiusXS
    
    color: root.checked ? root.activeColor : QsCommons.Color.mSurface
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

    QsComponents.CIcon {
      visible: root.checked
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: -1
      icon: "check"
      color: root.activeOnColor
      pointSize: Math.max(QsCommons.Style.fontSizeXS, root.baseSize * 0.5)
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
