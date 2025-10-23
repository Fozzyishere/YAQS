import QtQuick
import QtQuick.Controls

import qs.Commons

/**
 * RadioButton - Radio button for exclusive selection
 *
 * A radio button control with circular indicator and animated inner dot.
 * Used for mutually exclusive options in radio button groups.
 *
 * Features:
 * - Circular indicator with inner dot animation
 * - Smooth color transitions
 * - Text label support
 * - Per-screen scaling support
 * - Integrates with QtQuick RadioButton group behavior
 *
 * Usage:
 *   ButtonGroup { id: group }
 *   RadioButton { text: "Option 1"; checked: true; ButtonGroup.group: group }
 *   RadioButton { text: "Option 2"; ButtonGroup.group: group }
 *   RadioButton { text: "Option 3"; ButtonGroup.group: group }
 */
RadioButton {
    id: root

    // Public properties
    property real scaling: 1.0

    // Custom indicator (circular with inner dot)
    indicator: Rectangle {
        id: outerCircle

        implicitWidth: Math.round(Style.fontSize * 1.25 * scaling)
        implicitHeight: Math.round(Style.fontSize * 1.25 * scaling)
        radius: width * 0.5
        color: Color.transparent
        border.color: root.checked ? Color.mPrimary : Color.mOnSurface
        border.width: Math.max(1, Style.borderM * scaling)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on border.color {
            ColorAnimation {
                duration: Style.durationFast
            }
        }

        // Inner dot (only visible when checked)
        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.width * 0.3

            radius: width * 0.5
            color: root.checked ? Color.mPrimary : Color.transparent

            Behavior on color {
                ColorAnimation {
                    duration: Style.durationFast
                }
            }

            // Scale animation for check
            scale: root.checked ? 1.0 : 0.0
            Behavior on scale {
                NumberAnimation {
                    duration: Style.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // Custom content item (text label)
    contentItem: Text {
        text: root.text
        font.family: Style.fontFamily
        font.pixelSize: Math.round(Style.fontSize * scaling)
        font.weight: Font.Normal
        color: Color.mOnSurface
        verticalAlignment: Text.AlignVCenter
        leftPadding: outerCircle.width + Style.spacingS * scaling
    }
}
