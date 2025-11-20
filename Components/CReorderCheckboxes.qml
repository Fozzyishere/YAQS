import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

Rectangle {
  id: root

  // === Public Properties ===
  property var items: []  // Array of {id, label, checked}

  // === Signals ===
  signal orderChanged(var newOrder)
  signal itemToggled(string id, bool checked)

  // === Dimensions ===
  implicitWidth: 300
  implicitHeight: columnLayout.implicitHeight + QsCommons.Style.marginM * 2

  // === Appearance ===
  color: QsCommons.Color.mSurfaceVariant
  radius: QsCommons.Style.radiusM
  border.color: QsCommons.Color.mOutline
  border.width: QsCommons.Style.borderS

  // === Layout ===
  ColumnLayout {
    id: columnLayout
    anchors.fill: parent
    anchors.margins: QsCommons.Style.marginM
    spacing: QsCommons.Style.marginXS

    Repeater {
      model: root.items

      Rectangle {
        id: itemDelegate
        Layout.fillWidth: true
        Layout.preferredHeight: checkboxRow.implicitHeight + QsCommons.Style.marginS * 2

        property bool isDragging: dragHandler.active

        // Visual feedback during drag
        z: isDragging ? 100 : 1
        color: isDragging ? QsCommons.Color.mPrimaryContainer : QsCommons.Color.transparent
        radius: QsCommons.Style.radiusS
        border.color: isDragging ? QsCommons.Color.mPrimary : QsCommons.Color.transparent
        border.width: QsCommons.Style.borderS

        RowLayout {
          id: checkboxRow
          anchors.fill: parent
          anchors.margins: QsCommons.Style.marginS
          spacing: QsCommons.Style.marginM

          // Drag handle icon
          Text {
            id: dragHandle
            text: "⋮⋮"
            color: QsCommons.Color.mOnSurfaceVariant
            font.family: QsCommons.Settings.data.ui.fontDefault
            font.pixelSize: QsCommons.Style.fontSizeL
            Layout.preferredWidth: 20
            Layout.alignment: Qt.AlignVCenter

            DragHandler {
              id: dragHandler
              target: itemDelegate
              yAxis.enabled: true
              xAxis.enabled: false
              cursorShape: Qt.SizeVerCursor

              property int startIndex: index
              property real startY: 0

              onActiveChanged: {
                if (active) {
                  startIndex = index
                  startY = itemDelegate.y
                } else {
                  // Calculate new position
                  var itemHeight = itemDelegate.height + columnLayout.spacing
                  var newIndex = Math.round(itemDelegate.y / itemHeight)

                  // Clamp index
                  newIndex = Math.max(0, Math.min(newIndex, root.items.length - 1))

                  if (newIndex !== startIndex) {
                    var newItems = root.items.slice()
                    var item = newItems.splice(startIndex, 1)[0]
                    newItems.splice(newIndex, 0, item)
                    root.items = newItems
                    root.orderChanged(newItems)
                  }

                  // Reset position - Layout will handle it
                  itemDelegate.y = startY
                }
              }
            }
          }

          QsComponents.CCheckbox {
            Layout.fillWidth: true
            label: modelData.label
            checked: modelData.checked

            onToggled: isChecked => {
              var newItems = root.items.slice()
              newItems[index].checked = isChecked
              root.items = newItems
              root.itemToggled(modelData.id, isChecked)
            }
          }
        }
      }
    }
  }
}
