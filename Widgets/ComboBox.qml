import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Commons

/**
 * ComboBox - Dropdown selector with popup
 *
 * A dropdown selector with custom styled popup and key-based selection.
 * Model items should have 'key' and 'name' properties.
 *
 * Features:
 * - Optional label and description
 * - Key-based selection (not index-based)
 * - Custom styled popup with hover effects
 * - Placeholder text support
 * - Per-screen scaling support
 *
 * Usage:
 *   ComboBox {
 *       label: "Theme"
 *       description: "Select your color scheme"
 *       model: [
 *           {key: "gruvbox", name: "Gruvbox Dark"},
 *           {key: "catppuccin", name: "Catppuccin Mocha"}
 *       ]
 *       currentKey: "gruvbox"
 *       onSelected: (key) => console.log("Selected:", key)
 *   }
 */
RowLayout {
    id: root

    // Public properties
    property real minimumWidth: 200 * scaling
    property real popupHeight: 180 * scaling
    property string label: ""
    property string description: ""
    property var model
    property string currentKey: ""
    property string placeholder: "Select..."
    property real scaling: 1.0

    readonly property real preferredHeight: Math.round((Style.fontSize + Style.spacingM) * 1.5 * scaling)

    // Signals
    signal selected(string key)

    // Layout
    spacing: Style.spacingL * scaling
    Layout.fillWidth: true

    // Helper functions
    function itemCount() {
        if (!root.model) return 0
        if (typeof root.model.count === 'number') return root.model.count
        if (Array.isArray(root.model)) return root.model.length
        return 0
    }

    function getItem(index) {
        if (!root.model) return null
        if (typeof root.model.get === 'function') return root.model.get(index)
        if (Array.isArray(root.model)) return root.model[index]
        return null
    }

    function findIndexByKey(key) {
        for (var i = 0; i < itemCount(); i++) {
            var item = getItem(i)
            if (item && item.key === key) return i
        }
        return -1
    }

    // Label component
    FieldLabel {
        label: root.label
        description: root.description
        scaling: root.scaling
        visible: root.label !== "" || root.description !== ""
    }

    // ComboBox control
    ComboBox {
        id: combo

        Layout.minimumWidth: root.minimumWidth
        Layout.preferredHeight: root.preferredHeight
        model: root.model
        currentIndex: findIndexByKey(currentKey)

        onActivated: {
            var item = getItem(combo.currentIndex)
            if (item && item.key !== undefined) {
                root.selected(item.key)
            }
        }

        // Custom background
        background: Rectangle {
            implicitWidth: root.minimumWidth
            implicitHeight: preferredHeight
            color: Color.mSurface
            border.color: combo.activeFocus ? Color.mSecondary : Color.mOutline
            border.width: Math.max(1, Style.borderS * scaling)
            radius: Style.radiusM * scaling

            Behavior on border.color {
                ColorAnimation {
                    duration: Style.durationFast
                }
            }
        }

        // Custom content item (selected text)
        contentItem: Text {
            leftPadding: Style.spacingM * scaling
            rightPadding: combo.indicator.width + Style.spacingM * scaling
            text: {
                if (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) {
                    var item = getItem(combo.currentIndex)
                    return item ? item.name : root.placeholder
                }
                return root.placeholder
            }
            font.family: Style.fontFamily
            font.pixelSize: Math.round(Style.fontSize * scaling)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            color: (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) ?
                   Color.mOnSurface : Color.mOnSurfaceVariant
        }

        // Custom indicator (dropdown arrow)
        indicator: Text {
            x: combo.width - width - Style.spacingM * scaling
            y: combo.topPadding + (combo.availableHeight - height) / 2
            text: "▼"  // Down arrow
            font.family: Style.fontFamily
            font.pixelSize: Math.round(Style.fontSize * 0.7 * scaling)
            color: Color.mOnSurface
        }

        // Custom popup
        popup: Popup {
            y: combo.height + Style.spacingXs * scaling
            implicitWidth: combo.width
            implicitHeight: Math.min(root.popupHeight, contentItem.implicitHeight + Style.spacingM * scaling * 2)
            padding: Style.spacingM * scaling

            contentItem: ListView {
                id: listView
                model: combo.popup.visible ? root.model : null
                implicitHeight: contentHeight
                clip: true
                currentIndex: combo.currentIndex

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: ItemDelegate {
                    width: listView.width
                    height: Math.round((Style.fontSize + Style.spacingS) * 1.5 * scaling)
                    hoverEnabled: true
                    highlighted: ListView.isCurrentItem

                    onHoveredChanged: {
                        if (hovered) {
                            listView.currentIndex = index
                        }
                    }

                    onClicked: {
                        var item = root.getItem(index)
                        if (item && item.key !== undefined) {
                            root.selected(item.key)
                            combo.currentIndex = index
                            combo.popup.close()
                        }
                    }

                    background: Rectangle {
                        width: parent.width - Style.spacingM * scaling
                        color: highlighted ? Color.mTertiary : Color.transparent
                        radius: Style.radiusS * scaling

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.durationFast
                            }
                        }
                    }

                    contentItem: Text {
                        text: {
                            var item = root.getItem(index)
                            return item && item.name ? item.name : ""
                        }
                        font.family: Style.fontFamily
                        font.pixelSize: Math.round(Style.fontSize * scaling)
                        color: highlighted ? Color.mOnTertiary : Color.mOnSurface
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.durationFast
                            }
                        }
                    }
                }
            }

            background: Rectangle {
                color: Color.mSurfaceVariant
                border.color: Color.mOutline
                border.width: Math.max(1, Style.borderS * scaling)
                radius: Style.radiusM * scaling
            }
        }

        // Update currentIndex when currentKey changes externally
        Connections {
            target: root
            function onCurrentKeyChanged() {
                combo.currentIndex = root.findIndexByKey(currentKey)
            }
        }
    }
}
