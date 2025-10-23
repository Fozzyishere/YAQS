import QtQuick

import "../Commons"

/**
 * Button - Standard button with variant and size support
 *
 * Enhanced button component with Material Design 3 inspired variants and sizes.
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
 *   Button { text: "Save"; variant: "primary"; size: "medium" }
 *   Button { text: "Cancel"; variant: "outlined" }
 */
Rectangle {
    id: root

    // Public properties
    property string text: ""
    property bool active: false
    property string variant: ""         // "", "primary", "secondary", "outlined", "text"
    property string size: "medium"      // "small", "medium", "large"
    property color textColor: Color.mOnSurface  // Legacy property for bar widgets
    property real scaling: 1.0

    // Signals
    signal clicked

    // Internal properties
    property bool _hovered: false
    readonly property bool _useLegacyMode: variant === ""

    // Size-based dimensions
    implicitWidth: {
        if (_useLegacyMode) {
            // Legacy bar widget mode
            return Math.round((label.implicitWidth + Style.spacingM * 2) * scaling)
        }
        const baseWidth = label.implicitWidth + paddingH * 2
        switch (size) {
            case "small": return Math.round(baseWidth * 0.85 * scaling)
            case "large": return Math.round(baseWidth * 1.15 * scaling)
            default: return Math.round(baseWidth * scaling)
        }
    }

    implicitHeight: {
        if (_useLegacyMode) {
            // Legacy bar widget mode
            return Math.round((Settings.data.bar.height - Style.spacingS) * scaling)
        }
        switch (size) {
            case "small": return Math.round((Style.fontSize * 2) * scaling)
            case "large": return Math.round((Style.fontSize * 3) * scaling)
            default: return Math.round((Style.fontSize * 2.5) * scaling)
        }
    }

    readonly property real paddingH: Style.spacingM

    // Variant-based colors
    color: {
        if (_useLegacyMode) {
            // Legacy bar widget mode
            if (active) {
                return Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.2)
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

    readonly property color textColorValue: {
        if (_useLegacyMode) {
            return textColor
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

    radius: Style.radiusS * scaling

    // Label
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: textColorValue
        font.family: Style.fontFamily
        font.pixelSize: {
            if (_useLegacyMode) {
                return Math.round(Style.fontSize * scaling)
            }
            switch (size) {
                case "small": return Math.round(Style.fontSize * 0.9 * scaling)
                case "large": return Math.round(Style.fontSize * 1.1 * scaling)
                default: return Math.round(Style.fontSize * scaling)
            }
        }
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
            duration: Style.durationNormal
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Style.durationNormal
        }
    }
}
