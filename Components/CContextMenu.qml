import QtQuick
import QtQuick.Controls
import "../Commons" as QsCommons
import "../Components" as QsComponents
import "../Services" as QsServices

Menu {
  id: root

  // === Public Properties ===
  property real minWidth: Math.round(180 * QsCommons.Style.uiScaleRatio)
  property real itemHeight: Math.round(48 * QsCommons.Style.uiScaleRatio)

  // MD3 v2.0: Menu container styling
  background: Rectangle {
    implicitWidth: root.minWidth
    implicitHeight: root.itemHeight
    color: QsCommons.Color.mSurfaceContainer
    radius: QsCommons.Style.radiusM  // 16px (MD3)
    // MD3 v2.0: No border, uses elevation
    border.width: 0

    // Subtle shadow for elevation
    layer.enabled: true
    layer.effect: Item {
      Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.parent.radius + 2
        color: Qt.alpha(QsCommons.Color.mShadow, 0.15)
        z: -1
      }
    }
  }

  // Menu item delegate
  delegate: MenuItem {
    id: menuItem

    implicitWidth: Math.max(root.minWidth, contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: root.itemHeight

    leftPadding: QsCommons.Style.marginM
    rightPadding: QsCommons.Style.marginM

    contentItem: Row {
      spacing: QsCommons.Style.marginM

      QsComponents.CIcon {
        visible: menuItem.icon.name !== ""
        icon: menuItem.icon.name || ""
        pointSize: QsCommons.Style.fontSizeL
        color: menuItem.enabled 
          ? QsCommons.Color.mOnSurface 
          : QsCommons.Color.mOnSurfaceVariant
        anchors.verticalCenter: parent.verticalCenter
        opacity: menuItem.enabled ? 1.0 : QsCommons.Style.opacityDisabled
      }

      QsComponents.CText {
        text: menuItem.text
        pointSize: QsCommons.Style.fontSizeM
        color: menuItem.enabled 
          ? QsCommons.Color.mOnSurface 
          : QsCommons.Color.mOnSurfaceVariant
        anchors.verticalCenter: parent.verticalCenter
        opacity: menuItem.enabled ? 1.0 : QsCommons.Style.opacityDisabled
      }
    }

    background: Rectangle {
      // MD3 v2.0: 8% state layer on hover, no radius for menu items
      color: menuItem.highlighted 
        ? Qt.alpha(QsCommons.Color.mOnSurface, QsCommons.Style.opacityHover) 
        : QsCommons.Color.transparent
      // MD3: No radius on menu items (full-width)
      radius: 0

      Behavior on color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }
  }

  // Separator styling
  MenuSeparator {
    contentItem: Rectangle {
      implicitHeight: 1
      color: QsCommons.Color.mOutlineVariant
    }
  }

  // Panel service integration
  onOpened: {
    if (typeof QsServices.PanelService !== "undefined") {
      QsServices.PanelService.willOpenPopup(root)
    }
  }

  onClosed: {
    if (typeof QsServices.PanelService !== "undefined") {
      QsServices.PanelService.willClosePopup(root)
    }
  }
}

