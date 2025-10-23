import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Services

/**
 * BarPill - Expandable icon+text bar widget with interaction support
 *
 * A reusable bar widget component that displays an icon with optional text.
 * Supports hover states, click interactions, wheel scrolling, and tooltips.
 *
 * Features:
 * - Icon + text layout with smooth transitions
 * - Hover state management
 * - Click, right-click, and wheel scroll support
 * - Tooltip integration
 * - Display modes: always show text, show on hover, icon only
 * - Per-screen scaling support
 *
 * Usage:
 *   BarPill {
 *     icon: "󰕾"
 *     text: "50%"
 *     tooltipText: "Volume: 50%"
 *     showTextOnHover: true
 *     onClicked: { }
 *     onWheel: function(delta) { }
 *   }
 */
Item {
    id: root

    // Public properties
    property string icon: ""
    property string text: ""
    property string suffix: ""
    property string tooltipText: ""
    property color iconColor: Color.mOnSurface
    property color textColor: Color.mOnSurface
    property real scaling: 1.0

    // Display behavior
    property bool showText: true              // Whether to show text at all
    property bool showTextOnHover: false      // Only show text when hovering
    property bool enableTooltip: tooltipText !== ""
    property int tooltipDelay: 500

    // Interaction
    property bool clickable: true
    property bool acceptWheel: false
    property bool hovered: mouseArea.containsMouse

    // Signals
    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal wheel(int delta)

    // Auto-size to content
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    // Internal state
    readonly property bool _showingText: showText && (!showTextOnHover || hovered)
    readonly property string _displayText: text + (suffix && text !== "" ? suffix : "")

    // Layout
    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Math.round(Style.spacingXs * scaling)

        // Smooth spacing transition when text appears/disappears
        Behavior on spacing {
            NumberAnimation {
                duration: Style.durationNormal
                easing.type: Easing.InOutCubic
            }
        }

        // Icon
        Text {
            id: iconText
            visible: root.icon !== ""
            text: root.icon
            font.family: "Symbols Nerd Font"
            font.pixelSize: Math.round(Style.iconSize * scaling)
            color: root.iconColor

            Behavior on color {
                ColorAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.InOutCubic
                }
            }
        }

        // Text with smooth show/hide
        Item {
            id: textContainer
            Layout.preferredWidth: root._showingText ? labelText.implicitWidth : 0
            Layout.preferredHeight: labelText.implicitHeight

            opacity: root._showingText ? 1.0 : 0.0
            visible: opacity > 0
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.InOutCubic
                }
            }

            Text {
                id: labelText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root._displayText
                font.family: Style.fontFamily
                font.pixelSize: Math.round(Style.fontSize * scaling)
                color: root.textColor

                Behavior on color {
                    ColorAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }
    }

    // Mouse interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: clickable ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton) : Qt.NoButton
        cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.clicked()
            } else if (mouse.button === Qt.RightButton) {
                root.rightClicked()
            } else if (mouse.button === Qt.MiddleButton) {
                root.middleClicked()
            }
        }

        onWheel: function(wheelEvent) {
            if (root.acceptWheel) {
                root.wheel(wheelEvent.angleDelta.y)
                wheelEvent.accepted = true
            }
        }

        onEntered: {
            if (root.enableTooltip) {
                TooltipService.show(root, root.tooltipText, root.tooltipDelay)
            }
        }

        onExited: {
            if (root.enableTooltip) {
                TooltipService.hide()
            }
        }
    }
}