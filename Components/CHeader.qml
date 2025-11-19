import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

ColumnLayout {
  id: root

  // === Properties ===
  property string label: ""
  property string description: ""

  spacing: QsCommons.Style.marginXXS
  Layout.fillWidth: true
  Layout.bottomMargin: QsCommons.Style.marginM

  // === Content ===
  QsComponents.CText {
    text: root.label
    pointSize: QsCommons.Style.fontSizeXXL
    font.weight: QsCommons.Style.fontWeightBold
    color: QsCommons.Color.mSecondary
    visible: root.label !== ""
  }

  QsComponents.CText {
    text: root.description
    pointSize: QsCommons.Style.fontSizeS
    color: QsCommons.Color.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    visible: root.description !== ""
  }
}
