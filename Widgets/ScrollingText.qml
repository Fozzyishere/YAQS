import QtQuick

import qs.Commons

/**
 * ScrollingText - Auto-scrolling text container for overflow content
 *
 * A reusable text component that automatically scrolls when the content
 * is wider than the available space. Scrolling activates on hover and
 * smoothly resets when the cursor exits.
 *
 * Features:
 * - Automatic scroll detection based on content width
 * - Hover-activated scrolling animation
 * - Smooth reset animation on exit
 * - Seamless looping with duplicate text
 * - Configurable width and styling
 * - Per-screen scaling support
 *
 * Usage:
 *   ScrollingText {
 *     width: 200
 *     text: "Very long text that will scroll horizontally..."
 *     color: Color.mOnSurface
 *   }
 */
Item {
    id: root

    // Public properties
    property string text: ""
    property color color: Color.mOnSurface
    property real scaling: 1.0
    property real scrollSpeed: 100  // Characters per second
    property real scrollPadding: 50  // Spacing between original and duplicate text

    // Read-only state
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool needsScrolling: fullTextMetrics.contentWidth > root.width

    // Sizing
    implicitHeight: Math.round(Style.fontSize * 1.5 * scaling)
    clip: true

    // Hidden text for measuring full width
    Text {
        id: fullTextMetrics
        visible: false
        text: root.text
        font.family: Style.fontFamily
        font.pixelSize: Math.round(Style.fontSize * scaling)
    }

    // Scrolling container
    Item {
        id: scrollContainer
        height: parent.height
        width: childrenRect.width

        property real scrollX: 0
        x: scrollX

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(root.scrollPadding * scaling)

            // Primary text
            Text {
                id: primaryText
                text: root.text
                font.family: Style.fontFamily
                font.pixelSize: Math.round(Style.fontSize * scaling)
                color: root.color
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            // Duplicate text for seamless looping
            Text {
                visible: root.needsScrolling
                text: root.text
                font.family: Style.fontFamily
                font.pixelSize: Math.round(Style.fontSize * scaling)
                color: root.color
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }

        // Scroll animation (active on hover)
        NumberAnimation on scrollX {
            running: root.isHovered && root.needsScrolling
            from: 0
            to: -(fullTextMetrics.contentWidth + root.scrollPadding * scaling)
            duration: Math.max(3000, root.text.length * root.scrollSpeed)
            loops: Animation.Infinite
            easing.type: Easing.Linear
        }

        // Reset animation (on exit)
        Behavior on scrollX {
            enabled: !root.isHovered
            NumberAnimation {
                duration: Style.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    // Hover detection
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Only for hover detection

        onExited: {
            // Reset scroll position when exiting
            scrollContainer.scrollX = 0
        }
    }
}
