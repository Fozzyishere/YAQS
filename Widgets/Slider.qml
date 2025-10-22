import QtQuick
import QtQuick.Controls

import "../Commons"

/**
 * Slider - Range slider with gradient fill
 *
 * A beautiful slider control with animated gradient fill and circular cutout effect.
 * Based on Noctalia's NSlider with gorgeous visual design.
 *
 * Features:
 * - Animated gradient fill on active track
 * - Circular cutout around knob
 * - Smooth knob dragging
 * - Snap modes (always or on release)
 * - Configurable height ratio
 * - Per-screen scaling support
 *
 * Usage:
 *   Slider {
 *       from: 0
 *       to: 100
 *       value: 50
 *       stepSize: 1
 *       onMoved: console.log("Value:", value)
 *   }
 */
Slider {
    id: root

    // Public properties
    property var cutoutColor: Color.mSurface
    property bool snapAlways: true
    property real heightRatio: 0.7
    property real scaling: 1.0

    // Calculated dimensions
    readonly property real knobDiameter: Math.round((Style.fontSize * 2 * heightRatio * scaling) / 2) * 2
    readonly property real trackHeight: Math.round((knobDiameter * 0.4) / 2) * 2
    readonly property real cutoutExtra: Math.round((Style.fontSize * 0.4 * scaling) / 2) * 2

    padding: cutoutExtra / 2
    snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
    implicitHeight: Math.max(trackHeight, knobDiameter)

    // Custom background (track)
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 200 * scaling
        implicitHeight: trackHeight
        width: root.availableWidth
        height: implicitHeight
        radius: height / 2
        color: Qt.alpha(Color.mSurface, 0.5)
        border.color: Qt.alpha(Color.mOutline, 0.5)
        border.width: Math.max(1, Style.borderS * scaling)

        // Active track with gradient (composite shape)
        Item {
            id: activeTrackContainer
            width: root.visualPosition * parent.width
            height: parent.height
            clip: true

            // Rounded end cap
            Rectangle {
                width: parent.height
                height: parent.height
                radius: width / 2
                color: Qt.darker(Color.mPrimary, 1.2) // Gradient start
            }

            // Main gradient rectangle
            Rectangle {
                x: parent.height / 2
                width: parent.width - x
                height: parent.height
                radius: 0

                // Animated gradient fill
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.darker(Color.mPrimary, 1.2)
                        Behavior on color {
                            ColorAnimation { duration: 300 }
                        }
                    }
                    GradientStop {
                        position: 0.5
                        color: Color.mPrimary

                        // Animated gradient position (wave effect)
                        SequentialAnimation on position {
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 0.3
                                to: 0.7
                                duration: 2000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: 0.7
                                to: 0.3
                                duration: 2000
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.lighter(Color.mPrimary, 1.2)
                    }
                }
            }
        }

        // Circular cutout around knob
        Rectangle {
            id: knobCutout
            implicitWidth: knobDiameter + cutoutExtra
            implicitHeight: knobDiameter + cutoutExtra
            radius: width / 2
            color: root.cutoutColor !== undefined ? root.cutoutColor : Color.mSurface
            x: root.leftPadding + root.visualPosition * (root.availableWidth - root.knobDiameter) - cutoutExtra / 2
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Custom handle (knob)
    handle: Item {
        implicitWidth: knobDiameter
        implicitHeight: knobDiameter
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2

        Rectangle {
            id: knob
            implicitWidth: knobDiameter
            implicitHeight: knobDiameter
            radius: width / 2
            color: root.pressed ? Color.mTertiary : Color.mSurface
            border.color: Color.mPrimary
            border.width: Math.max(1, Style.borderL * scaling)
            anchors.centerIn: parent

            Behavior on color {
                ColorAnimation {
                    duration: Style.durationFast
                }
            }
        }
    }
}
