import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Services" as QsServices
import "../Components" as QsComponents

RowLayout {
  id: root

  property real minimumWidth: 280 * QsCommons.Style.uiScaleRatio
  property real popupHeight: 180 * QsCommons.Style.uiScaleRatio

  property string label: ""
  property string description: ""
  property var model
  property string currentKey: ""
  property string placeholder: ""

  readonly property real preferredHeight: QsCommons.Style.baseWidgetSize * 1.1 * QsCommons.Style.uiScaleRatio

  signal selected(string key)

  spacing: QsCommons.Style.marginL
  Layout.fillWidth: true

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
      implicitWidth: QsCommons.Style.baseWidgetSize * 3.75
      implicitHeight: preferredHeight
      color: QsCommons.Color.mSurface
      border.color: combo.activeFocus ? QsCommons.Color.mSecondary : QsCommons.Color.mOutline
      border.width: QsCommons.Style.borderS
      radius: QsCommons.Style.radiusM

      Behavior on border.color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }

    contentItem: QsComponents.CText {
      leftPadding: QsCommons.Style.marginM
      rightPadding: combo.indicator.width + QsCommons.Style.marginM
      
      pointSize: QsCommons.Style.fontSizeM
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      color: (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) ? QsCommons.Color.mOnSurface : QsCommons.Color.mOnSurfaceVariant
      text: (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) ? (getItem(combo.currentIndex) ? getItem(combo.currentIndex).name : root.placeholder) : root.placeholder
    }

    indicator: QsComponents.CIcon {
      x: combo.width - width - QsCommons.Style.marginM
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "caret-down"
      pointSize: QsCommons.Style.fontSizeL
    }

    popup: Popup {
      y: combo.height
      implicitWidth: combo.width - QsCommons.Style.marginM
      implicitHeight: Math.min(root.popupHeight, contentItem.implicitHeight + QsCommons.Style.marginM * 2)
      padding: QsCommons.Style.marginM

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
            width: parentComboBox ? parentComboBox.width - QsCommons.Style.marginM * 3 : 0
            color: highlighted ? QsCommons.Color.mTertiary : QsCommons.Color.transparent
            radius: QsCommons.Style.radiusS
            
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
            color: highlighted ? QsCommons.Color.mOnTertiary : QsCommons.Color.mOnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            
            Behavior on color {
              ColorAnimation {
                duration: QsCommons.Style.animationFast
              }
            }
          }
        }
      }

      background: Rectangle {
        color: QsCommons.Color.mSurfaceVariant
        border.color: QsCommons.Color.mOutline
        border.width: QsCommons.Style.borderS
        radius: QsCommons.Style.radiusM
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
