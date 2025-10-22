import QtQuick
import QtQuick.Layouts

import "../../../Commons"
import "../../../Services"

Item {
    id: root

    // ===== Properties =====
    property var screen: null
    property real scaling: 1.0

    // ===== Visibility =====
    visible: MediaService.currentPlayer !== null && MediaService.trackTitle !== ""

    // Auto-size to content
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    // ===== Layout =====
    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Math.round(Style.spacingXs * scaling)

        // ===== Icon =====
        Text {
            text: MediaService.getIcon()
            font.family: "Symbols Nerd Font"
            font.pixelSize: Math.round(Style.iconSize * scaling)
            color: MediaService.getColor()

            // Smooth color transitions
            Behavior on color {
                ColorAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.InOutCubic
                }
            }
        }

        // ===== Scrolling Track Info =====
        Item {
            Layout.preferredWidth: Math.round(150 * scaling)  // Fixed width for scrolling
            Layout.preferredHeight: trackText.height
            clip: true

            // Scrolling text container
            Text {
                id: trackText
                text: MediaService.getTrackDisplay()
                font.family: Style.fontFamily
                font.pixelSize: Math.round(Style.fontSize * scaling)
                color: MediaService.getColor()

                // Smooth color transitions
                Behavior on color {
                    ColorAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.InOutCubic
                    }
                }

                // Horizontal offset for scrolling
                property real xOffset: 0
                x: xOffset

                // Scroll animation when text is too wide
                NumberAnimation on xOffset {
                    id: scrollAnimation
                    running: trackText.width > trackText.parent.width && mouseArea.containsMouse
                    from: 0
                    to: -(trackText.width - trackText.parent.width + 10)  // +10 for padding
                    duration: Math.max(3000, trackText.text.length * 100)
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }

                // Reset to start when not hovering
                Behavior on xOffset {
                    enabled: !scrollAnimation.running
                    NumberAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.OutCubic
                    }
                }

                // Reset offset when not hovering
                Component.onCompleted: {
                    if (!mouseArea.containsMouse) {
                        xOffset = 0;
                    }
                }
            }
        }
    }

    // ===== Interaction =====
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                MediaService.playPause();
                Logger.log("MediaMini", "Play/Pause toggled");
            } else if (mouse.button === Qt.RightButton) {
                MediaService.next();
                Logger.log("MediaMini", "Next track");
            } else if (mouse.button === Qt.MiddleButton) {
                MediaService.previous();
                Logger.log("MediaMini", "Previous track");
            }
        }

        // Tooltip and reset scroll position
        onEntered: {
            let tooltip = MediaService.getTrackDisplay();

            if (MediaService.trackAlbum) {
                tooltip += "\nAlbum: " + MediaService.trackAlbum;
            }

            tooltip += "\n";
            if (MediaService.canGoPrevious) tooltip += "Middle-click: Previous\n";
            tooltip += "Left-click: Play/Pause\n";
            if (MediaService.canGoNext) tooltip += "Right-click: Next";

            TooltipService.show(root, tooltip.trim(), 500);
        }

        onExited: {
            trackText.xOffset = 0;
            TooltipService.hide();
        }
    }
}
