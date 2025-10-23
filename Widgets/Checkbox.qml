import QtQuick
import QtQuick.Layouts

import qs.Commons

/**
 * Checkbox - Checkbox with animated checkmark
 *
 * A checkbox control with label, description, and smooth animated checkmark.
 * Uses a compact layout suitable for settings and forms.
 *
 * Features:
 * - Optional label and description
 * - Animated checkmark icon
 * - Hover effects
 * - Customizable active color
 * - Per-screen scaling support
 *
 * Usage:
 *   Checkbox {
 *       label: "Enable feature"
 *       description: "Toggle this feature on or off"
 *       checked: true
 *       onToggled: (checked) => console.log("Checked:", checked)
 *   }
 */
RowLayout {
    id: root

    // Public properties
    property string label: ""
    property string description: ""
    property bool checked: false
    property bool hovering: false
    property color activeColor: Color.mPrimary
    property color activeOnColor: Color.mOnPrimary
    property real scaling: 1.0
    property int baseSize: Math.round(Style.fontSize * 1.4 * scaling)

    // Signals
    signal toggled(bool checked)
    signal entered
    signal exited

    // Layout
    Layout.fillWidth: true
    spacing: Style.spacingM * scaling

    // Label component (if provided)
    FieldLabel {
        label: root.label
        description: root.description
        scaling: root.scaling
        visible: root.label !== "" || root.description !== ""
        Layout.fillWidth: true
    }

    // Spacer to push checkbox to the right
    Item {
        Layout.fillWidth: true
        visible: root.label !== "" || root.description !== ""
    }

    // Checkbox box
    Rectangle {
        id: box

        implicitWidth: root.baseSize
        implicitHeight: root.baseSize
        radius: Style.radiusXs * scaling
        color: root.checked ? root.activeColor : Color.mSurface
        border.color: root.checked ? root.activeColor : Color.mOutline
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

        // Checkmark icon
        Text {
            visible: root.checked
            anchors.centerIn: parent
            text: "✓"  // Checkmark character
            font.family: Style.fontFamily
            font.pixelSize: Math.round(root.baseSize * 0.65)
            font.weight: Font.Bold
            color: root.activeOnColor

            // Fade in animation
            opacity: root.checked ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
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
            onClicked: root.toggled(!root.checked)
        }
    }
}
