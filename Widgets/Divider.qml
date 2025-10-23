import QtQuick

import qs.Commons

/**
 * Divider - Visual separator line
 *
 * A simple horizontal or vertical line used to visually separate content sections.
 * Automatically adjusts width/height based on orientation.
 *
 * Features:
 * - Horizontal or vertical orientation
 * - Configurable thickness and color
 * - Per-screen scaling support
 * - Minimal, clean design
 *
 * Usage:
 *   Divider { }  // Horizontal divider (default)
 *   Divider { orientation: "vertical"; thickness: 2 }
 */
Rectangle {
    id: root

    // Public properties
    property string orientation: "horizontal"  // "horizontal" or "vertical"
    property real thickness: Style.borderS
    property color color: Color.mOutline
    property real scaling: 1.0

    // Auto-size based on orientation
    width: orientation === "horizontal" ? parent.width : Math.max(1, thickness * scaling)
    height: orientation === "vertical" ? parent.height : Math.max(1, thickness * scaling)
    color: root.color
}
