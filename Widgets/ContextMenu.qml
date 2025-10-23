import QtQuick
import QtQuick.Controls

import qs.Commons

/**
 * ContextMenu - Right-click popup menu
 *
 * A styled context menu for right-click actions. Model items should have
 * 'key', 'text', 'icon', and optionally 'enabled' properties.
 *
 * Features:
 * - Custom styled menu items
 * - Icon support
 * - Disabled item support
 * - Keyboard navigation
 * - Auto-positioning
 * - Per-screen scaling support
 *
 * Usage:
 *   ContextMenu {
 *       id: contextMenu
 *       model: [
 *           {key: "copy", text: "Copy", icon: "󰆏", enabled: true},
 *           {key: "paste", text: "Paste", icon: "󰆒", enabled: false},
 *           {key: "delete", text: "Delete", icon: "󰆴", enabled: true}
 *       ]
 *       onItemClicked: (key) => console.log("Clicked:", key)
 *   }
 *
 *   MouseArea {
 *       acceptedButtons: Qt.RightButton
 *       onClicked: contextMenu.popup()
 *   }
 */
Menu {
    id: root

    // Public properties
    property var model: []
    property real scaling: 1.0

    // Signals
    signal itemClicked(string key)

    // Appearance
    padding: Style.spacingS * scaling

    // Custom background
    background: Rectangle {
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
        radius: Style.radiusM * scaling
    }

    // Generate menu items from model
    Repeater {
        model: root.model

        MenuItem {
            required property var modelData
            required property int index

            text: modelData.text || ""
            enabled: modelData.enabled !== undefined ? modelData.enabled : true
            height: Math.round((Style.fontSize + Style.spacingM) * 1.2 * scaling)

            onTriggered: {
                root.itemClicked(modelData.key)
                root.close()
            }

            // Custom content item
            contentItem: Row {
                spacing: Style.spacingS * scaling
                leftPadding: Style.spacingM * scaling
                rightPadding: Style.spacingM * scaling

                // Icon (if provided)
                Text {
                    visible: parent.parent.modelData.icon !== undefined &&
                             parent.parent.modelData.icon !== ""
                    text: parent.parent.modelData.icon || ""
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(Style.fontSize * 1.1 * scaling)
                    color: parent.parent.enabled ? Color.mOnSurface : Color.mOnSurfaceVariant
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Text
                Text {
                    text: parent.parent.text
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(Style.fontSize * scaling)
                    color: parent.parent.enabled ? Color.mOnSurface : Color.mOnSurfaceVariant
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Custom background with hover effect
            background: Rectangle {
                color: parent.highlighted ? Color.mTertiary : Color.transparent
                radius: Style.radiusS * scaling

                Behavior on color {
                    ColorAnimation {
                        duration: Style.durationFast
                    }
                }
            }
        }
    }
}
