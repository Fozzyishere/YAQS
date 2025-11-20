import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

Rectangle {
  id: root

  // === Public Properties ===
  property color initialColor: "#ffffff"
  property color selectedColor: initialColor

  // === Signals ===
  signal accepted(color color)
  signal rejected()

  // === Dimensions ===
  implicitWidth: 400
  implicitHeight: columnLayout.implicitHeight + QsCommons.Style.marginL * 2

  // === Appearance ===
  color: QsCommons.Color.mSurface
  radius: QsCommons.Style.radiusL
  border.color: QsCommons.Color.mPrimary
  border.width: QsCommons.Style.borderS

  // === Layout ===
  ColumnLayout {
    id: columnLayout
    anchors.fill: parent
    anchors.margins: QsCommons.Style.marginL
    spacing: QsCommons.Style.marginL

    Text {
      text: "Choose Color"
      font.family: QsCommons.Settings.data.ui.fontDefault
      font.pixelSize: QsCommons.Style.fontSizeXXL
      font.weight: QsCommons.Style.fontWeightBold
      color: QsCommons.Color.mOnSurface
    }

    QsComponents.CColorPicker {
      Layout.fillWidth: true
      selectedColor: root.selectedColor
      onColorPicked: newColor => root.selectedColor = newColor
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: QsCommons.Style.marginM

      Item {
        Layout.fillWidth: true
      }  // Spacer

      QsComponents.CButton {
        text: "Cancel"
        outlined: true
        onClicked: root.rejected()
      }

      QsComponents.CButton {
        text: "OK"
        onClicked: root.accepted(root.selectedColor)
      }
    }
  }
}
