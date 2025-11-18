import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons

ColumnLayout {
  id: root

  // === Public Properties ===
  property string label: ""
  property string description: ""
  property color labelColor: QsCommons.Color.mOnSurface
  property color descriptionColor: QsCommons.Color.mOnSurfaceVariant

  // === Layout ===
  spacing: QsCommons.Style.marginXXS
  Layout.fillWidth: true

  // === Child Components ===
  CText {
    text: label
    pointSize: QsCommons.Style.fontSizeL
    font.weight: QsCommons.Style.fontWeightBold
    color: labelColor
    visible: label !== ""
    Layout.fillWidth: true
  }

  CText {
    text: description
    pointSize: QsCommons.Style.fontSizeS
    color: descriptionColor
    wrapMode: Text.WordWrap
    visible: description !== ""
    Layout.fillWidth: true
  }
}
