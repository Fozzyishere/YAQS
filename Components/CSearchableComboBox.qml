import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Services" as QsServices
import "../Components" as QsComponents
import "../Helpers/FuzzySort.js" as Fuzzysort

RowLayout {
  id: root

  // === Public Properties ===
  property string label: ""
  property string description: ""
  property ListModel model: ListModel {}
  property string currentKey: ""
  property string placeholder: ""
  property string searchPlaceholder: "Search..."
  property Component delegate: null

  // === Sizing ===
  // baseSize controls overall combobox scale
  property real baseSize: QsCommons.Style.baseWidgetSize * 1.4 * QsCommons.Style.uiScaleRatio

  // Local dimensions
  readonly property real preferredHeight: Math.round(baseSize)
  readonly property real minimumWidth: Math.round(280 * QsCommons.Style.uiScaleRatio)
  readonly property real popupHeight: Math.round(180 * QsCommons.Style.uiScaleRatio)
  readonly property real popupGap: Math.round(4 * QsCommons.Style.uiScaleRatio)

  // === Signals ===
  signal selected(string key)

  spacing: QsCommons.Style.marginL
  Layout.fillWidth: true

  // === Internal State ===
  property ListModel filteredModel: ListModel {}
  property string searchText: ""

  // === Helper Functions ===
  function findIndexByKey(key) {
    for (var i = 0; i < root.model.count; i++) {
      if (root.model.get(i).key === key) {
        return i
      }
    }
    return -1
  }

  function findIndexByKeyInFiltered(key) {
    for (var i = 0; i < root.filteredModel.count; i++) {
      if (root.filteredModel.get(i).key === key) {
        return i
      }
    }
    return -1
  }

  function filterModel() {
    filteredModel.clear()

    // Check if model exists and has items
    if (!root.model || root.model.count === undefined || root.model.count === 0) {
      return
    }

    if (searchText.trim() === "") {
      // If no search text, show all items
      for (var i = 0; i < root.model.count; i++) {
        filteredModel.append(root.model.get(i))
      }
    } else {
      // Convert ListModel to array for fuzzy search
      var items = []
      for (var i = 0; i < root.model.count; i++) {
        items.push(root.model.get(i))
      }

      // Use fuzzy search if available, fallback to simple search
      if (typeof Fuzzysort !== 'undefined') {
        var fuzzyResults = Fuzzysort.go(searchText, items, {
                                          "key": "name",
                                          "threshold": -1000,
                                          "limit": 50
                                        })

        // Add results in order of relevance
        for (var j = 0; j < fuzzyResults.length; j++) {
          filteredModel.append(fuzzyResults[j].obj)
        }
      } else {
        // Fallback to simple search
        var searchLower = searchText.toLowerCase()
        for (var i = 0; i < items.length; i++) {
          var item = items[i]
          if (item.name.toLowerCase().includes(searchLower)) {
            filteredModel.append(item)
          }
        }
      }
    }
  }

  onSearchTextChanged: filterModel()
  onModelChanged: filterModel()

  QsComponents.CLabel {
    label: root.label
    description: root.description
  }

  Item {
    Layout.fillWidth: true
  }

  ComboBox {
    id: combo

    Layout.minimumWidth: root.minimumWidth
    Layout.preferredHeight: root.preferredHeight
    model: filteredModel
    currentIndex: findIndexByKeyInFiltered(currentKey)
    
    onActivated: {
      if (combo.currentIndex >= 0 && combo.currentIndex < filteredModel.count) {
        root.selected(filteredModel.get(combo.currentIndex).key)
      }
    }

    background: Rectangle {
      implicitWidth: root.minimumWidth
      implicitHeight: root.preferredHeight
      radius: QsCommons.Style.radiusS
      
      color: QsCommons.Color.mSurfaceContainer
      border.color: combo.activeFocus ? QsCommons.Color.mPrimary : QsCommons.Color.transparent
      border.width: combo.activeFocus ? QsCommons.Style.borderM : 0

      Behavior on border.color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
      
      Behavior on border.width {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }

    contentItem: QsComponents.CText {
      leftPadding: QsCommons.Style.marginS
      rightPadding: combo.indicator.width + QsCommons.Style.marginS
      
      pointSize: QsCommons.Style.fontSizeM
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      color: (combo.currentIndex >= 0 && combo.currentIndex < filteredModel.count) ? QsCommons.Color.mOnSurface : QsCommons.Color.mOnSurfaceVariant
      text: (combo.currentIndex >= 0 && combo.currentIndex < filteredModel.count) ? filteredModel.get(combo.currentIndex).name : root.placeholder
    }

    indicator: QsComponents.CIcon {
      x: combo.width - width - QsCommons.Style.marginS
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "caret-down"
      pointSize: QsCommons.Style.fontSizeL
    }

    popup: Popup {
      y: combo.height + root.popupGap
      width: combo.width
      height: root.popupHeight + root.preferredHeight
      padding: QsCommons.Style.marginXS

      onOpened: {
        QsServices.PanelService.willOpenPopup(root)
      }

      onClosed: {
        QsServices.PanelService.willClosePopup(root)
      }

      contentItem: ColumnLayout {
        spacing: QsCommons.Style.marginS

        QsComponents.CTextInput {
          id: searchInput
          Layout.fillWidth: true
          placeholderText: root.searchPlaceholder
          text: root.searchText
          onTextChanged: root.searchText = text
        }

        ListView {
          id: listView
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: combo.popup.visible ? filteredModel : null
          clip: true

          ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AsNeeded
          }

          delegate: root.delegate ? root.delegate : defaultDelegate

          Component {
            id: defaultDelegate
            ItemDelegate {
              id: delegateRoot
              width: listView.width
              hoverEnabled: true
              highlighted: ListView.view.currentIndex === index

              onHoveredChanged: {
                if (hovered) {
                  ListView.view.currentIndex = index
                }
              }

              onClicked: {
                root.selected(filteredModel.get(index).key)
                combo.currentIndex = root.findIndexByKeyInFiltered(filteredModel.get(index).key)
                combo.popup.close()
              }

              contentItem: QsComponents.CText {
                text: name
                pointSize: QsCommons.Style.fontSizeM
                color: QsCommons.Color.mOnSurface
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: QsCommons.Style.marginM
              }

              background: Rectangle {
                width: listView.width
                color: highlighted ? Qt.alpha(QsCommons.Color.mOnSurface, QsCommons.Style.opacityHover) : QsCommons.Color.transparent
                radius: 0
                
                Behavior on color {
                  ColorAnimation {
                    duration: QsCommons.Style.animationFast
                  }
                }
              }
            }
          }
        }
      }

      background: Rectangle {
        radius: QsCommons.Style.radiusM
        color: QsCommons.Color.mSurfaceContainer
        border.width: QsCommons.Style.borderNone
      }
    }

    // Update the currentIndex if the currentKey is changed externally
    Connections {
      target: root
      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexByKeyInFiltered(currentKey)
      }
    }

    // Focus search input when popup opens and ensure model is filtered
    Connections {
      target: combo.popup
      function onVisibleChanged() {
        if (combo.popup.visible) {
          // Ensure the model is filtered when popup opens
          filterModel()
          // Small delay to ensure the popup is fully rendered
          Qt.callLater(() => {
                         if (searchInput) {
                           searchInput.forceActiveFocus()
                         }
                       })
        }
      }
    }
  }
}
