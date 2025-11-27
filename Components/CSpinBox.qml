import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property int value: 0
  property int from: 0
  property int to: 100
  property int stepSize: 1
  property string suffix: ""
  property string label: ""
  property string description: ""

  // === Sizing ===
  // baseSize controls overall spinbox scale. Components derive dimensions locally.
  // Default: Style.baseWidgetSize * 1.2 gives ~48px height at default scale
  property real baseSize: QsCommons.Style.baseWidgetSize * 1.2 * QsCommons.Style.uiScaleRatio

  // Local dimension calculations (self-contained)
  readonly property real inputHeight: Math.round(baseSize)                           // ~48px at default
  readonly property real inputWidth: Math.round(150 * QsCommons.Style.uiScaleRatio)  // Default width
  readonly property real buttonSize: Math.round(baseSize * 0.7)                      // Button size

  spacing: QsCommons.Style.marginM

  QsComponents.CLabel {
    label: root.label
    description: root.description
    visible: root.label !== "" || root.description !== ""
  }

  Rectangle {
    implicitWidth: root.inputWidth
    implicitHeight: root.inputHeight
    radius: QsCommons.Style.radiusS

    color: QsCommons.Color.mSurfaceContainer
    // MD3: No border by default
    border.width: QsCommons.Style.borderNone

    Row {
      anchors.fill: parent
      anchors.leftMargin: QsCommons.Style.marginXS
      anchors.rightMargin: QsCommons.Style.marginXS
      spacing: 0

      QsComponents.CIconButton {
        icon: "minus"
        baseSize: root.buttonSize
        shouldApplyUiScale: false  // Already scaled via root.baseSize
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.value > root.from
        
        onClicked: {
          root.value = Math.max(root.from, root.value - root.stepSize)
        }
      }

      Text {
        width: parent.width - (root.buttonSize * 2)
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
        baseSize: root.buttonSize
        shouldApplyUiScale: false  // Already scaled via root.baseSize
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.value < root.to
        
        onClicked: {
          root.value = Math.min(root.to, root.value + root.stepSize)
        }
      }
    }
  }
}
