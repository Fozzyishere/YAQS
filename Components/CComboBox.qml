import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Services" as QsServices
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property string label: ""
  property string description: ""
  property var model
  property string currentKey: ""
  property string placeholder: ""

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

  // === Helper Functions ===
  function itemCount() {
    if (!root.model)
      return 0
    if (typeof root.model.count === 'number')
      return root.model.count
    if (Array.isArray(root.model))
      return root.model.length
    return 0
  }

  function getItem(index) {
    if (!root.model)
      return null
    if (typeof root.model.get === 'function')
      return root.model.get(index)
    if (Array.isArray(root.model))
      return root.model[index]
    return null
  }

  function findIndexByKey(key) {
    for (var i = 0; i < itemCount(); i++) {
      var item = getItem(i)
      if (item && item.key === key)
        return i
    }
    return -1
  }

  QsComponents.CLabel {
    label: root.label
    description: root.description
  }

  ComboBox {
    id: combo

    Layout.minimumWidth: root.minimumWidth
    Layout.preferredHeight: root.preferredHeight
    model: model
    currentIndex: findIndexByKey(currentKey)
    
    onActivated: {
      var item = getItem(combo.currentIndex)
      if (item && item.key !== undefined)
        root.selected(item.key)
    }

    background: Rectangle {
      implicitWidth: root.minimumWidth
      implicitHeight: root.preferredHeight
      radius: QsCommons.Style.radiusS
      
      color: QsCommons.Color.mSurfaceContainer
      // Focus state shows border, otherwise transparent/minimal
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
      color: (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) ? QsCommons.Color.mOnSurface : QsCommons.Color.mOnSurfaceVariant
      text: (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) ? (getItem(combo.currentIndex) ? getItem(combo.currentIndex).name : root.placeholder) : root.placeholder
    }

    indicator: QsComponents.CIcon {
      x: combo.width - width - QsCommons.Style.marginS
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "caret-down"
      pointSize: QsCommons.Style.fontSizeL
    }

    popup: Popup {
      y: combo.height + root.popupGap
      implicitWidth: combo.width
      implicitHeight: Math.min(root.popupHeight, contentItem.implicitHeight + QsCommons.Style.marginXS * 2)
      padding: QsCommons.Style.marginXS

      onOpened: {
        QsServices.PanelService.willOpenPopup(root)
      }

      onClosed: {
        QsServices.PanelService.willClosePopup(root)
      }

      contentItem: ListView {
        model: combo.popup.visible ? root.model : null
        implicitHeight: contentHeight
        clip: true

        ScrollBar.vertical: ScrollBar {
          active: true
          policy: ScrollBar.AsNeeded
        }

        delegate: ItemDelegate {
          property var parentComboBox: combo
          property int itemIndex: index
          width: parentComboBox ? parentComboBox.width : 0
          hoverEnabled: true
          highlighted: ListView.view.currentIndex === itemIndex

          onHoveredChanged: {
            if (hovered) {
              ListView.view.currentIndex = itemIndex
            }
          }

          onClicked: {
            var item = root.getItem(itemIndex)
            if (item && item.key !== undefined && parentComboBox) {
              root.selected(item.key)
              parentComboBox.currentIndex = itemIndex
              parentComboBox.popup.close()
            }
          }

          background: Rectangle {
            width: parentComboBox ? parentComboBox.width - QsCommons.Style.marginXS * 2 : 0
            // List items show 8% state layer on hover
            color: highlighted ? Qt.alpha(QsCommons.Color.mOnSurface, QsCommons.Style.opacityHover) : QsCommons.Color.transparent
            radius: 0
            
            Behavior on color {
              ColorAnimation {
                duration: QsCommons.Style.animationFast
              }
            }
          }

          contentItem: QsComponents.CText {
            text: {
              var item = root.getItem(index)
              return item && item.name ? item.name : ""
            }
            pointSize: QsCommons.Style.fontSizeM
            color: QsCommons.Color.mOnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            leftPadding: QsCommons.Style.marginM
          }
        }
      }

      background: Rectangle {
        radius: QsCommons.Style.radiusM
        color: QsCommons.Color.mSurfaceContainer
        // Popup uses elevation, not border
        border.width: QsCommons.Style.borderNone
      }
    }

    // Update the currentIndex if the currentKey is changed externally
    Connections {
      target: root
      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexByKey(currentKey)
      }
    }
  }
}
