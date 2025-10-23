import QtQuick
import QtQuick.Layouts

import qs.Commons

/**
 * ListItem - List row with icon, title, subtitle, and trailing component
 *
 * A list item component for use in lists like WiFi networks,
 * Bluetooth devices, launcher results, etc.
 *
 * Features:
 * - Optional leading icon
 * - Title and optional subtitle (2-line support)
 * - Optional trailing component (button, toggle, etc.)
 * - Hover effects
 * - Clickable with signal
 * - Per-screen scaling support
 *
 * Usage:
 *   ListItem {
 *       icon: "󰖩"
 *       title: "My WiFi Network"
 *       subtitle: "Connected • Strong signal"
 *       onClicked: console.log("Clicked")
 *
 *       trailing: Button { text: "Forget" }
 *   }
 */
Rectangle {
    id: root

    // Public properties
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool hovered: false
    property real scaling: 1.0
    property real iconSize: Style.fontSize * 1.5 * scaling
    property Component trailing: null

    // Signals
    signal clicked

    // Appearance
    implicitWidth: parent.width
    implicitHeight: Math.round((Style.fontSize * 3 + Style.spacingL * 2) * scaling)
    color: hovered ? Color.mSurfaceVariant : Color.transparent
    radius: Style.radiusM * scaling

    Behavior on color {
        ColorAnimation {
            duration: Style.durationFast
        }
    }

    // Content layout
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.spacingM * scaling
        anchors.rightMargin: Style.spacingM * scaling
        spacing: Style.spacingM * scaling

        // Leading icon (if provided)
        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Style.fontFamily
            font.pixelSize: Math.round(root.iconSize)
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignVCenter
        }

        // Title and subtitle column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Style.spacingXxs * scaling

            // Title
            Text {
                text: root.title
                font.family: Style.fontFamily
                font.pixelSize: Math.round(Style.fontSize * scaling)
                font.weight: Font.Medium
                color: Color.mOnSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Subtitle (if provided)
            Text {
                visible: root.subtitle !== ""
                text: root.subtitle
                font.family: Style.fontFamily
                font.pixelSize: Math.round(Style.fontSize * 0.85 * scaling)
                font.weight: Font.Normal
                color: Color.mOnSurfaceVariant
                elide: Text.ElideRight
                opacity: 0.87
                Layout.fillWidth: true
            }
        }

        // Trailing component loader (if provided)
        Loader {
            visible: root.trailing !== null
            sourceComponent: root.trailing
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Mouse area for hover and click
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}