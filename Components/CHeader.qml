import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

ColumnLayout {
  id: root

  // === Properties ===
  property string label: ""
  property string description: ""
  // Primary text color for headings
  property color labelColor: QsCommons.Color.mOnSurface
  property color descriptionColor: QsCommons.Color.mOnSurfaceVariant

  spacing: QsCommons.Style.marginXXS
  Layout.fillWidth: true
  Layout.bottomMargin: QsCommons.Style.marginM

  // === Content ===
  QsComponents.CText {
    text: root.label
    pointSize: QsCommons.Style.fontSizeXXL
    font.weight: QsCommons.Style.fontWeightBold
    color: root.labelColor
    visible: root.label !== ""
  }

  QsComponents.CText {
    text: root.description
    pointSize: QsCommons.Style.fontSizeS
    color: root.descriptionColor
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    visible: root.description !== ""
  }
}
