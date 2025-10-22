import QtQuick
import QtQuick.Controls

import "../Commons"

/**
 * ProgressBar - Progress indicator
 *
 * A progress bar with gradient fill and support for determinate/indeterminate modes.
 * Used for showing loading progress, system stats (CPU/Memory/Disk), etc.
 *
 * Features:
 * - Gradient-filled progress indicator
 * - Rounded ends
 * - Indeterminate animation (future enhancement)
 * - Configurable colors
 * - Per-screen scaling support
 *
 * Usage:
 *   ProgressBar {
 *       from: 0
 *       to: 100
 *       value: 75
 *   }
 */
ProgressBar {
    id: root

    // Public properties
    property real scaling: 1.0
    property color barColor: Color.mPrimary
    property color backgroundColor: Color.mSurfaceVariant
    property real heightRatio: 0.5

    // Calculated dimensions
    readonly property real barHeight: Math.round(Style.fontSize * heightRatio * scaling)

    implicitHeight: barHeight

    // Custom background
    background: Rectangle {
        implicitWidth: 200 * scaling
        implicitHeight: barHeight
        radius: height / 2
        color: root.backgroundColor
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
    }

    // Custom content item (filled portion)
    contentItem: Item {
        implicitWidth: 200 * scaling
        implicitHeight: barHeight

        // Progress fill
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: height / 2
            clip: true

            // Gradient fill
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Qt.darker(root.barColor, 1.1)
                }
                GradientStop {
                    position: 0.5
                    color: root.barColor
                }
                GradientStop {
                    position: 1.0
                    color: Qt.lighter(root.barColor, 1.1)
                }
            }

            // Smooth animation on value change
            Behavior on width {
                NumberAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
