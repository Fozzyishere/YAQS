import QtQuick
import Quickshell.Widgets

import "../Commons"

/**
 * ImageRounded - Rounded rectangle image
 *
 * An image with rounded corners using QuickShell's ClippingWrapperRectangle.
 * Supports fallback icon if image fails to load or path is empty.
 *
 * Features:
 * - Rounded corners (configurable radius)
 * - Async image loading
 * - Fallback icon support
 * - Border support
 * - Status change signal
 * - Per-screen scaling support
 *
 * Usage:
 *   ImageRounded {
 *       width: 64
 *       height: 64
 *       imagePath: "/path/to/image.png"
 *       imageRadius: 8
 *       fallbackIcon: "󰋩"
 *   }
 */
ClippingWrapperRectangle {
    id: root

    // Public properties
    property string imagePath: ""
    property color borderColor: Color.transparent
    property real borderWidth: 0
    property real imageRadius: Style.radiusM * scaling
    property string fallbackIcon: ""
    property real fallbackIconSize: Style.fontSize * 2 * scaling
    property real scaling: 1.0

    // Signals
    signal statusChanged(int status)

    // Appearance
    color: Color.transparent
    radius: imageRadius
    border.color: borderColor
    border.width: Math.max(0, borderWidth * scaling)

    // Image component
    Image {
        id: img
        anchors.fill: parent
        source: root.imagePath
        fillMode: Image.PreserveAspectCrop
        mipmap: true
        smooth: true
        asynchronous: true
        cache: true

        onStatusChanged: root.statusChanged(status)

        // Fallback icon when image fails or empty
        Text {
            visible: (root.imagePath === "" || img.status === Image.Error || img.status === Image.Null) &&
                     root.fallbackIcon !== ""
            anchors.centerIn: parent
            text: root.fallbackIcon
            font.family: Style.fontFamily
            font.pixelSize: Math.round(root.fallbackIconSize)
            color: Color.mOnSurface
        }
    }
}
