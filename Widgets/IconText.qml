import QtQuick
import QtQuick.Layouts

import qs.Commons

/**
 * IconText - Icon + Text layout with smooth color transitions
 *
 * Reusable component for displaying an icon with optional text.
 * Features automatic color animations and consistent styling.
 *
 * Features:
 * - Icon with nerd font support
 * - Optional text with configurable visibility
 * - Smooth color transitions
 * - Per-screen scaling support
 * - Configurable spacing
 *
 * Usage:
 *   IconText {
 *     icon: "󰕾"
 *     text: "50%"
 *     iconColor: Color.mPrimary
 *     textColor: Color.mOnSurface
 *   }
 */
RowLayout {
    id: root

    // Public properties
    property string icon: ""
    property string text: ""
    property bool showText: text !== ""
    property color iconColor: Color.mOnSurface
    property color textColor: Color.mOnSurface
    property real scaling: 1.0

    spacing: Math.round(Style.spacingXs * scaling)

    // Icon
    Text {
        id: iconText
        visible: root.icon !== ""
        text: root.icon
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(Style.iconSize * scaling)
        color: root.iconColor

        Behavior on color {
            ColorAnimation {
                duration: Style.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // Text
    Text {
        id: labelText
        visible: root.showText
        text: root.text
        font.family: Style.fontFamily
        font.pixelSize: Math.round(Style.fontSize * scaling)
        color: root.textColor

        Behavior on color {
            ColorAnimation {
                duration: Style.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }
}