import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T

import qs.Commons

/**
 * ScrollView - Scrollable container with custom scrollbars
 *
 * A scrollable container with styled scrollbars that fade in/out.
 * Configures internal Flickable to prevent unwanted horizontal scrolling.
 *
 * Features:
 * - Custom styled scrollbars (thin, colored)
 * - Fade in/out on scroll
 * - Prevent horizontal scroll option
 * - Configurable scroll policies
 * - Per-screen scaling support
 *
 * Usage:
 *   ScrollView {
 *       width: 400
 *       height: 600
 *
 *       ColumnLayout {
 *           // Your scrollable content here
 *       }
 *   }
 */
T.ScrollView {
    id: root

    // Public properties
    property color handleColor: Qt.alpha(Color.mTertiary, 0.8)
    property color handleHoverColor: handleColor
    property color handlePressedColor: handleColor
    property color trackColor: Color.transparent
    property real handleWidth: 6 * scaling
    property real handleRadius: Style.radiusM * scaling
    property int verticalPolicy: ScrollBar.AsNeeded
    property int horizontalPolicy: ScrollBar.AsNeeded
    property bool preventHorizontalScroll: horizontalPolicy === ScrollBar.AlwaysOff
    property int boundsBehavior: Flickable.StopAtBounds
    property int flickableDirection: Flickable.VerticalFlick
    property real scaling: 1.0

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    // Configure the internal flickable when available
    Component.onCompleted: {
        configureFlickable()
    }

    // Function to configure the underlying Flickable
    function configureFlickable() {
        // Find the internal Flickable (usually the first child)
        for (var i = 0; i < children.length; i++) {
            var child = children[i]
            if (child.toString().indexOf("Flickable") !== -1) {
                // Configure the flickable
                child.boundsBehavior = root.boundsBehavior

                if (root.preventHorizontalScroll) {
                    child.flickableDirection = Flickable.VerticalFlick
                    child.contentWidth = Qt.binding(() => child.width)
                } else {
                    child.flickableDirection = root.flickableDirection
                }
                break
            }
        }
    }

    // Watch for changes in horizontalPolicy
    onHorizontalPolicyChanged: {
        preventHorizontalScroll = (horizontalPolicy === ScrollBar.AlwaysOff)
        configureFlickable()
    }

    // Vertical scrollbar
    ScrollBar.vertical: ScrollBar {
        parent: root
        x: root.mirrored ? 0 : root.width - width
        y: root.topPadding
        height: root.availableHeight
        active: root.ScrollBar.horizontal.active
        policy: root.verticalPolicy

        contentItem: Rectangle {
            implicitWidth: root.handleWidth
            implicitHeight: 100
            radius: root.handleRadius
            color: parent.pressed ? root.handlePressedColor :
                   parent.hovered ? root.handleHoverColor : root.handleColor
            opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.durationFast
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.durationFast
                }
            }
        }

        background: Rectangle {
            implicitWidth: root.handleWidth
            implicitHeight: 100
            color: root.trackColor
            opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 0.3 : 0.0
            radius: root.handleRadius / 2

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.durationFast
                }
            }
        }
    }

    // Horizontal scrollbar
    ScrollBar.horizontal: ScrollBar {
        parent: root
        x: root.leftPadding
        y: root.height - height
        width: root.availableWidth
        active: root.ScrollBar.vertical.active
        policy: root.horizontalPolicy

        contentItem: Rectangle {
            implicitWidth: 100
            implicitHeight: root.handleWidth
            radius: root.handleRadius
            color: parent.pressed ? root.handlePressedColor :
                   parent.hovered ? root.handleHoverColor : root.handleColor
            opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.durationFast
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.durationFast
                }
            }
        }

        background: Rectangle {
            implicitWidth: 100
            implicitHeight: root.handleWidth
            color: root.trackColor
            opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 0.3 : 0.0
            radius: root.handleRadius / 2

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.durationFast
                }
            }
        }
    }
}
