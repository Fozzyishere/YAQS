import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property alias from: slider.from
  property alias to: slider.to
  property alias value: slider.value
  property alias stepSize: slider.stepSize
  property string suffix: ""
  property string text: ""

  // === Sizing ===
  // Inherits sizing from CSlider via composition
  // Value label has its own local sizing
  readonly property real valueLabelWidth: Math.round(50 * QsCommons.Style.uiScaleRatio)

  // === Signals ===
  signal moved

  spacing: QsCommons.Style.marginM
  
  QsComponents.CSlider {
    id: slider
    Layout.fillWidth: true
    onMoved: root.moved()
  }

  Text {
    text: root.text !== "" ? root.text : (Math.round(slider.value) + root.suffix)
    color: QsCommons.Color.mOnSurface
    font.family: QsCommons.Settings.data.ui.fontFixed
    font.pointSize: QsCommons.Style.fontSizeM * QsCommons.Style.uiScaleRatio
    font.weight: QsCommons.Style.fontWeightMedium
    Layout.minimumWidth: root.valueLabelWidth
    horizontalAlignment: Text.AlignRight
    verticalAlignment: Text.AlignVCenter
  }
}
