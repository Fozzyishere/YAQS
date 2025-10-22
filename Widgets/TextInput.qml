import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Commons"

/**
 * TextInput - Single-line text input field
 *
 * A text input field with label, placeholder, focus states, and proper mouse event handling.
 * Includes advanced mouse event blocking to prevent interaction issues in panels.
 *
 * Features:
 * - Optional label and description above field
 * - Placeholder text support
 * - Focus border animation (mSecondary when focused)
 * - Read-only and disabled states
 * - Per-screen scaling support
 * - Mouse event capture to prevent background dragging
 *
 * Usage:
 *   TextInput {
 *       label: "Username"
 *       description: "Enter your system username"
 *       placeholderText: "john_doe"
 *       text: "current_value"
 *       onEditingFinished: console.log("Text changed:", text)
 *   }
 */
ColumnLayout {
    id: root

    // Public properties
    property string label: ""
    property string description: ""
    property bool readOnly: false
    property bool enabled: true
    property color labelColor: Color.mOnSurface
    property color descriptionColor: Color.mOnSurfaceVariant
    property real scaling: 1.0

    // Text field properties (aliased for convenience)
    property alias text: input.text
    property alias placeholderText: input.placeholderText
    property alias inputMethodHints: input.inputMethodHints
    property alias inputItem: input

    // Signals
    signal editingFinished

    // Layout
    spacing: Style.spacingS * scaling

    // Label component
    Label {
        label: root.label
        description: root.description
        labelColor: root.labelColor
        descriptionColor: root.descriptionColor
        scaling: root.scaling
        visible: root.label !== "" || root.description !== ""
        Layout.fillWidth: true
    }

    // Active control that blocks input to avoid event leakage
    Control {
        id: frameControl

        Layout.fillWidth: true
        Layout.minimumWidth: 80 * scaling
        implicitHeight: Math.round((Style.fontSize + Style.spacingM * 2) * 1.5 * scaling)

        // Makes the control accept focus
        focusPolicy: Qt.StrongFocus
        hoverEnabled: true

        // Background frame
        background: Rectangle {
            id: frame

            radius: Style.radiusM * scaling
            color: Color.mSurface
            border.color: input.activeFocus ? Color.mSecondary : Color.mOutline
            border.width: Math.max(1, Style.borderS * scaling)

            Behavior on border.color {
                ColorAnimation {
                    duration: Style.durationFast
                }
            }
        }

        contentItem: Item {
            // Invisible background that captures ALL mouse events
            MouseArea {
                id: backgroundCapture
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                preventStealing: true
                propagateComposedEvents: false

                onPressed: mouse => {
                    mouse.accepted = true
                    // Focus the input and position cursor
                    input.forceActiveFocus()
                    var inputPos = mapToItem(inputContainer, mouse.x, mouse.y)
                    if (inputPos.x >= 0 && inputPos.x <= inputContainer.width) {
                        var textPos = inputPos.x - Style.spacingM * scaling
                        if (textPos >= 0 && textPos <= input.width) {
                            input.cursorPosition = input.positionAt(textPos, input.height / 2)
                        }
                    }
                }

                onReleased: mouse => {
                    mouse.accepted = true
                }
                onDoubleClicked: mouse => {
                    mouse.accepted = true
                    input.selectAll()
                }
                onPositionChanged: mouse => {
                    mouse.accepted = true
                }
                onWheel: wheel => {
                    wheel.accepted = true
                }
            }

            // Container for the actual text field
            Item {
                id: inputContainer
                anchors.fill: parent
                anchors.leftMargin: Style.spacingM * scaling
                anchors.rightMargin: Style.spacingM * scaling
                z: 1

                TextField {
                    id: input

                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter

                    echoMode: TextInput.Normal
                    readOnly: root.readOnly
                    enabled: root.enabled
                    color: Color.mOnSurface
                    placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.6)

                    selectByMouse: true

                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0

                    background: null

                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(Style.fontSize * scaling)
                    font.weight: Font.Normal

                    onEditingFinished: root.editingFinished()

                    // Override mouse handling to prevent propagation
                    MouseArea {
                        id: textFieldMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        preventStealing: true
                        propagateComposedEvents: false
                        cursorShape: Qt.IBeamCursor

                        property int selectionStart: 0

                        onPressed: mouse => {
                            mouse.accepted = true
                            input.forceActiveFocus()
                            var pos = input.positionAt(mouse.x, mouse.y)
                            input.cursorPosition = pos
                            selectionStart = pos
                        }

                        onPositionChanged: mouse => {
                            if (mouse.buttons & Qt.LeftButton) {
                                mouse.accepted = true
                                var pos = input.positionAt(mouse.x, mouse.y)
                                input.select(selectionStart, pos)
                            }
                        }

                        onDoubleClicked: mouse => {
                            mouse.accepted = true
                            input.selectAll()
                        }

                        onReleased: mouse => {
                            mouse.accepted = true
                        }
                        onWheel: wheel => {
                            wheel.accepted = true
                        }
                    }
                }
            }
        }
    }
}
