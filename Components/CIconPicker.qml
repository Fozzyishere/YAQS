import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

Rectangle {
  id: root

  // === Public Properties ===
  property string selectedIcon: ""
  property var iconList: []
  property alias searchText: searchInput.text

  // === Signals ===
  signal iconSelected(string icon)

  // === Dimensions ===
  implicitWidth: 400
  implicitHeight: 500

  // === Appearance ===
  color: QsCommons.Color.mSurfaceVariant
  radius: QsCommons.Style.radiusM
  border.color: QsCommons.Color.mOutline
  border.width: QsCommons.Style.borderS

  // === Layout ===
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: QsCommons.Style.marginM
    spacing: QsCommons.Style.marginM

    // Search field
    QsComponents.CTextInput {
      id: searchInput
      Layout.fillWidth: true
      placeholderText: "Search icons..."
      clearButtonEnabled: true
    }

    // Icon grid
    QsComponents.CScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      Grid {
        id: iconGrid
        width: parent.width
        columns: Math.floor(width / (QsCommons.Style.baseWidgetSize + QsCommons.Style.marginXS))
        spacing: QsCommons.Style.marginXS

        Repeater {
          model: filteredModel

          QsComponents.CIconButton {
            icon: modelData
            tooltipText: modelData

            colorBg: root.selectedIcon === modelData ? QsCommons.Color.mPrimaryContainer : QsCommons.Color.transparent
            colorFg: root.selectedIcon === modelData ? QsCommons.Color.mPrimary : QsCommons.Color.mOnSurface

            onClicked: {
              root.selectedIcon = modelData
              root.iconSelected(modelData)
            }
          }
        }
      }
    }
  }

  // === Private Properties ===
  property var filteredModel: {
    var text = searchText.toLowerCase()
    if (text === "") return iconList
    return iconList.filter(icon => icon.toLowerCase().includes(text))
  }

  // === Initialization ===
  Component.onCompleted: {
    // Load icon list from TablerIcons via Icons singleton
    var icons = QsCommons.Icons.icons
    if (icons) {
      iconList = Object.keys(icons).sort()
    }
  }
}
