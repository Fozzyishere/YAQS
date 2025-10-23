import QtQuick

import qs.Commons

/**
 * BusyIndicator - Loading spinner
 *
 * A Canvas-based rotating arc spinner for indicating loading/busy states.
 * Uses a 270° arc with 90° gap that rotates continuously.
 *
 * Features:
 * - Smooth rotating animation
 * - Customizable color and size
 * - Configurable stroke width
 * - Can be stopped/started with 'running' property
 * - Per-screen scaling support
 *
 * Usage:
 *   BusyIndicator {
 *       running: isLoading
 *       size: 32
 *       color: Color.mPrimary
 *   }
 */
Item {
    id: root

    // Public properties
    property bool running: true
    property color color: Color.mPrimary
    property int size: Math.round(Style.fontSize * 2 * scaling)
    property int strokeWidth: Math.max(2, Style.borderL * scaling)
    property int duration: Style.durationSlow * 2
    property real scaling: 1.0

    implicitWidth: size
    implicitHeight: size

    // Canvas for drawing the spinner
    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(width, height) / 2 - root.strokeWidth / 2

            ctx.strokeStyle = root.color
            ctx.lineWidth = root.strokeWidth
            ctx.lineCap = "round"

            // Draw arc with gap (270 degrees with 90 degree gap)
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius,
                   -Math.PI / 2 + rotationAngle,
                   -Math.PI / 2 + rotationAngle + Math.PI * 1.5)
            ctx.stroke()
        }

        property real rotationAngle: 0

        onRotationAngleChanged: {
            requestPaint()
        }

        // Rotation animation
        NumberAnimation {
            target: canvas
            property: "rotationAngle"
            running: root.running
            from: 0
            to: 2 * Math.PI
            duration: root.duration
            loops: Animation.Infinite
        }
    }
}
