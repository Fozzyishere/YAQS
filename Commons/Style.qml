pragma Singleton

import QtQuick
import Quickshell

// Material Design 3 Style Tokens
QtObject {
    id: root

    // Spacing scale
    readonly property int spacing0: 0
    readonly property int spacingXxs: 1
    readonly property int spacingXs: 2
    readonly property int spacingS: 4
    readonly property int spacingM: 8
    readonly property int spacingL: 12
    readonly property int spacingXl: 16
    readonly property int spacing2xl: 24
    readonly property int spacing3xl: 32

    // Border radius scale
    readonly property int radiusXs: 2
    readonly property int radiusS: 4
    readonly property int radiusM: 8
    readonly property int radiusL: 12
    readonly property int radiusXl: 16
    readonly property int radiusFull: 9999

    // Animation durations (Material Design motion)
    readonly property int durationInstant: 0
    readonly property int durationFast: 100      // Short transitions
    readonly property int durationNormal: 200    // Standard transitions
    readonly property int durationSlow: 300      // Emphasized transitions

    // Opacity scale
    readonly property real opacityNone: 0.0
    readonly property real opacityLight: 0.25
    readonly property real opacityMedium: 0.5
    readonly property real opacityHeavy: 0.75
    readonly property real opacityFull: 1.0

    // Typography
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSizeSmall: 5       // Caption/helper text
    readonly property int fontSize: 7            // Body text
    readonly property int fontSizeLarge: 9       // Subheadings
    readonly property int fontSizeXlarge: 9      // Headings

    // Icon sizes
    readonly property int iconSize: 9

    // Border widths
    readonly property int borderS: 1
    readonly property int borderM: 2
    readonly property int borderL: 3
}
