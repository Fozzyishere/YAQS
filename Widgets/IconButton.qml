import QtQuick

import "../Commons"

/**
 * IconButton - Icon-only button with variant and size support
 *
 * Enhanced icon button component with Material Design 3 inspired variants and sizes.
 * Supports multiple visual styles and size presets for different use cases.
 *
 * Features:
 * - 4 variants: primary, secondary, outlined, text
 * - 3 sizes: small, medium, large
 * - Hover and active states
 * - Smooth color transitions
 * - Per-screen scaling support
 * - Backward compatible (defaults maintain original behavior for bar widgets)
 *
 * Usage:
 *   IconButton { icon: "󰒲"; variant: "primary"; sizePreset: "medium" }
 *   IconButton { icon: "󰅖"; variant: "outlined" }
 */
Rectangle {
    id: root

    // Public properties
    property string icon: ""
    property bool active: false
    property string variant: ""         // "", "primary", "secondary", "outlined", "text"
    property string sizePreset: "medium"  // "small", "medium", "large"
    property int size: Style.iconSize    // Legacy property for bar widgets
    property color iconColor: Color.mOnSurface  // Legacy property for bar widgets
    property real scaling: 1.0

    // Signals
    signal clicked

    // Internal properties
    property bool _hovered: false
    readonly property bool _useLegacyMode: variant === ""

    // Size-based dimensions
    readonly property real iconSize: {
        if (_useLegacyMode) {
            // Legacy bar widget mode
            return size
        }
        const baseSize = Style.iconSize
        switch (sizePreset) {
            case "small": return baseSize * 0.85
            case "large": return baseSize * 1.25
            default: return baseSize
        }
    }

    readonly property real buttonPadding: {
        if (_useLegacyMode) {
            return Style.spacingS
        }
        switch (sizePreset) {
            case "small": return Style.spacingS * 0.75
            case "large": return Style.spacingS * 1.5
            default: return Style.spacingS
        }
    }

    implicitWidth: Math.round((iconSize + buttonPadding * 2) * scaling)
    implicitHeight: Math.round((iconSize + buttonPadding * 2) * scaling)

    // Variant-based colors
    color: {
        if (_useLegacyMode) {
            // Legacy bar widget mode
            if (active) {
                return Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 0.2)
            }
            if (_hovered) {
                return Color.mSurfaceVariant
            }
            return Color.transparent
        }

        if (_hovered) {
            return Qt.lighter(backgroundColor, 1.1)
        }
        return backgroundColor
    }

    readonly property color backgroundColor: {
        if (variant === "text" || variant === "outlined") {
            return Color.transparent
        }
        if (variant === "secondary") {
            return Color.mSurfaceVariant
        }
        return Color.mPrimary  // primary
    }

    readonly property color iconColorValue: {
        if (_useLegacyMode) {
            return iconColor
        }
        if (variant === "outlined" || variant === "text") {
            return Color.mPrimary
        }
        if (variant === "secondary") {
            return Color.mOnSurface
        }
        return Color.mOnPrimary  // primary
    }

    // Border for outlined variant
    border.width: variant === "outlined" ? Math.max(1, Style.borderS * scaling) : 0
    border.color: variant === "outlined" ? Color.mPrimary : Color.transparent

    radius: {
        if (_useLegacyMode) {
            return Style.radiusS * scaling
        }
        // Circular for primary/secondary, rounded for outlined/text
        if (variant === "primary" || variant === "secondary") {
            return width * 0.5
        }
        return Style.radiusM * scaling
    }

    // Icon
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Style.fontFamily
        font.pixelSize: Math.round(root.iconSize * root.scaling)
        color: iconColorValue
        font.weight: root.active ? Font.Medium : Font.Normal
    }

    // Mouse interaction
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
        onEntered: root._hovered = true
        onExited: root._hovered = false
    }

    // Color transition
    Behavior on color {
        ColorAnimation {
            duration: Style.durationFast
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Style.durationFast
        }
    }
}
