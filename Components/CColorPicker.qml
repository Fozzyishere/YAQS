import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

Rectangle {
  id: root

  // === Public Properties ===
  property color selectedColor: "#ffffff"
  property bool showHexInput: true

  // === Signals ===
  signal colorPicked(color newColor)

  // === Dimensions ===
  implicitWidth: 300
  implicitHeight: columnLayout.implicitHeight + QsCommons.Style.marginL * 2

  // === Appearance ===
  color: QsCommons.Color.mSurfaceVariant
  radius: QsCommons.Style.radiusM
  border.color: QsCommons.Color.mOutline
  border.width: QsCommons.Style.borderS

  // === Layout ===
  ColumnLayout {
    id: columnLayout
    anchors.fill: parent
    anchors.margins: QsCommons.Style.marginL
    spacing: QsCommons.Style.marginM

    // Color preview
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 60
      color: root.selectedColor
      radius: QsCommons.Style.radiusS
      border.color: QsCommons.Color.mOutline
      border.width: QsCommons.Style.borderS
    }

    // RGB Sliders
    RowLayout {
      Layout.fillWidth: true
      spacing: QsCommons.Style.marginXS

      Text {
        text: "R"
        color: QsCommons.Color.mOnSurface
        font.family: QsCommons.Settings.data.ui.fontDefault
        font.pixelSize: QsCommons.Style.fontSizeM
        Layout.preferredWidth: 20
      }

      QsComponents.CSlider {
        id: redSlider
        Layout.fillWidth: true
        from: 0
        to: 255
        stepSize: 1
        value: root.selectedColor.r * 255
        onValueChanged: if (pressed) updateColor()
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: QsCommons.Style.marginXS

      Text {
        text: "G"
        color: QsCommons.Color.mOnSurface
        font.family: QsCommons.Settings.data.ui.fontDefault
        font.pixelSize: QsCommons.Style.fontSizeM
        Layout.preferredWidth: 20
      }

      QsComponents.CSlider {
        id: greenSlider
        Layout.fillWidth: true
        from: 0
        to: 255
        stepSize: 1
        value: root.selectedColor.g * 255
        onValueChanged: if (pressed) updateColor()
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: QsCommons.Style.marginXS

      Text {
        text: "B"
        color: QsCommons.Color.mOnSurface
        font.family: QsCommons.Settings.data.ui.fontDefault
        font.pixelSize: QsCommons.Style.fontSizeM
        Layout.preferredWidth: 20
      }

      QsComponents.CSlider {
        id: blueSlider
        Layout.fillWidth: true
        from: 0
        to: 255
        stepSize: 1
        value: root.selectedColor.b * 255
        onValueChanged: if (pressed) updateColor()
      }
    }

    // Hex input
    QsComponents.CTextInput {
      visible: root.showHexInput
      Layout.fillWidth: true
      placeholderText: "#ffffff"
      text: root.selectedColor.toString()
      onTextChanged: {
        if (activeFocus && text.match(/^#[0-9A-Fa-f]{6}$/)) {
          root.selectedColor = text
          root.colorPicked(root.selectedColor)
        }
      }
    }
  }

  // === Private Functions ===
  function updateColor() {
    var r = redSlider.value / 255
    var g = greenSlider.value / 255
    var b = blueSlider.value / 255
    root.selectedColor = Qt.rgba(r, g, b, 1)
    root.colorPicked(root.selectedColor)
  }
}
