import QtQuick
import QtQuick.Layouts

import "../Commons"

/**
 * Toggle - iOS-style toggle switch
 *
 * A toggle switch with smooth sliding knob animation and color transitions.
 * Provides a more visual alternative to checkboxes for boolean settings.
 *
 * Features:
 * - Optional label and description
 * - Smooth sliding knob animation
 * - Background color transitions
 * - Hover effects
 * - Per-screen scaling support
 *
 * Usage:
 *   Toggle {
 *       label: "Dark Mode"
 *       description: "Enable dark theme"
 *       checked: false
 *       onToggled: (checked) => console.log("Toggled:", checked)
 *   }
 */
RowLayout {
    id: root

    // Public properties
    property string label: ""
    property string description: ""
    property bool checked: false
    property bool hovering: false
    property real scaling: 1.0
    property int baseSize: Math.round(Style.fontSize * 1.6 * scaling)

    // Signals
    signal toggled(bool checked)
    signal entered
    signal exited

    // Layout
    Layout.fillWidth: true
    spacing: Style.spacingM * scaling

    // Label component (if provided)
    Label {
        label: root.label
        description: root.description
        scaling: root.scaling
        visible: root.label !== "" || root.description !== ""
        Layout.fillWidth: true
    }

    // Spacer to push toggle to the right (only if label exists)
    Item {
        Layout.fillWidth: true
        visible: root.label !== "" || root.description !== ""
    }

    // Toggle switch container
    Rectangle {
        id: switcher

        implicitWidth: Math.round(root.baseSize * 1.7)
        implicitHeight: root.baseSize
        radius: height * 0.5
        color: root.checked ? Color.mPrimary : Color.mSurface
        border.color: root.checked ? Color.mPrimary : Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)

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

        // Sliding knob
        Rectangle {
            id: knob

            implicitWidth: Math.round(root.baseSize * 0.75)
            implicitHeight: Math.round(root.baseSize * 0.75)
            radius: height * 0.5
            color: root.checked ? Color.mOnPrimary : Color.mOnSurface
            border.color: Color.transparent
            border.width: 0
            anchors.verticalCenter: parent.verticalCenter

            // Position based on checked state
            x: root.checked ?
                switcher.width - width - Math.round(3 * scaling) :
                Math.round(3 * scaling)

            Behavior on x {
                NumberAnimation {
                    duration: Style.durationFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.durationFast
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: {
                root.hovering = true
                root.entered()
            }
            onExited: {
                root.hovering = false
                root.exited()
            }
            onClicked: {
                root.toggled(!root.checked)
            }
        }
    }
}
