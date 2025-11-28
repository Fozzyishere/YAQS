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
  property string actionIcon: "search"
  property string actionTooltip: ""
  property bool actionEnabled: true

  // === Signals ===
  signal actionTriggered()
  signal textAccepted()

  spacing: QsCommons.Style.marginXS
  Layout.fillWidth: true

  // Text input
  QsComponents.CTextInput {
    id: input
    Layout.fillWidth: true

    onAccepted: {
      root.textAccepted()
    }
  }

  // Action button
  QsComponents.CIconButton {
    icon: root.actionIcon
    tooltipText: root.actionTooltip
    enabled: root.actionEnabled

    onClicked: {
      root.actionTriggered()
    }
  }
}

