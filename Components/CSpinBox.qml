import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  property int value: 0
  property int from: 0
  property int to: 100
  property int stepSize: 1
  property string suffix: ""
  property string label: ""
  property string description: ""

  spacing: QsCommons.Style.marginM

  QsComponents.CLabel {
    label: root.label
    description: root.description
    visible: root.label !== "" || root.description !== ""
  }

  Rectangle {
    implicitWidth: 150 * QsCommons.Style.uiScaleRatio
    implicitHeight: QsCommons.Style.baseWidgetSize * 1.1
    radius: QsCommons.Style.radiusS

    color: QsCommons.Color.mSurfaceVariant
    border.color: QsCommons.Color.mOutline
    border.width: QsCommons.Style.borderS

    Row {
      anchors.fill: parent
      anchors.leftMargin: QsCommons.Style.marginXS
      anchors.rightMargin: QsCommons.Style.marginXS
      spacing: 0

      QsComponents.CIconButton {
        icon: "minus"
        baseSize: parent.height * 0.7
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.value > root.from
        
        onClicked: {
          root.value = Math.max(root.from, root.value - root.stepSize)
        }
      }

      Text {
        width: parent.width - (parent.height * 0.7 * 2)
        height: parent.height
        text: root.value + root.suffix
        color: QsCommons.Color.mOnSurface
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: QsCommons.Settings.data.ui.fontDefault
        font.pointSize: QsCommons.Style.fontSizeM * QsCommons.Style.uiScaleRatio
        font.weight: QsCommons.Style.fontWeightMedium
      }

      QsComponents.CIconButton {
        icon: "plus"
        baseSize: parent.height * 0.7
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.value < root.to
        
        onClicked: {
          root.value = Math.min(root.to, root.value + root.stepSize)
        }
      }
    }
  }
}
