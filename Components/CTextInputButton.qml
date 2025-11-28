import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property alias text: input.text
  property alias placeholderText: input.placeholderText
  property alias readOnly: input.readOnly
  property string buttonText: "Submit"
  property string buttonIcon: ""
  property bool buttonEnabled: true

  // === Signals ===
  signal submitted()

  spacing: QsCommons.Style.marginXS
  Layout.fillWidth: true

  // Text input
  QsComponents.CTextInput {
    id: input
    Layout.fillWidth: true

    onAccepted: {
      if (root.buttonEnabled) {
        root.submitted()
      }
    }
  }

  // Submit button
  QsComponents.CButton {
    text: root.buttonText
    icon: root.buttonIcon
    enabled: root.buttonEnabled

    onClicked: {
      root.submitted()
    }
  }
}

