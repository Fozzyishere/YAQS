import QtQuick
import QtQuick.Layouts

import "../Commons"

/**
 * Label - Multi-line text display component
 *
 * A flexible label widget that supports both a main label and optional description text.
 * Used throughout the UI for form labels, section headers, and descriptive text.
 *
 * Features:
 * - Main label with customizable size and color
 * - Optional description text in smaller/lighter font
 * - Automatic layout management
 * - Per-screen scaling support
 * - Word wrapping for long text
 *
 * Usage:
 *   Label {
 *       label: "Username"
 *       description: "Enter your system username"
 *   }
 */
ColumnLayout {
    id: root

    // Public properties
    property string label: ""
    property string description: ""
    property color labelColor: Color.mOnSurface
    property color descriptionColor: Color.mOnSurfaceVariant
    property real scaling: 1.0
    property real labelSize: Style.fontSize * scaling
    property real descriptionSize: (Style.fontSize * 0.85) * scaling
    property bool visible: label !== "" || description !== ""

    // Layout
    Layout.fillWidth: true
    spacing: Style.spacingXxs * scaling

    // Main label text
    Text {
        id: labelText
        visible: root.label !== ""
        text: root.label
        color: root.labelColor
        font.family: Style.fontFamily
        font.pixelSize: Math.round(root.labelSize)
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    // Description text (smaller, lighter)
    Text {
        id: descriptionText
        visible: root.description !== ""
        text: root.description
        color: root.descriptionColor
        font.family: Style.fontFamily
        font.pixelSize: Math.round(root.descriptionSize)
        font.weight: Font.Normal
        wrapMode: Text.WordWrap
        opacity: 0.87
        Layout.fillWidth: true
    }
}
