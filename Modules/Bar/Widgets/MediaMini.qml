import QtQuick
import QtQuick.Layouts

import "../../../Commons"
import "../../../Services"
import "../../../Widgets"

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
        ScrollingText {
            id: trackScroller
            Layout.preferredWidth: Math.round(150 * scaling)
            scaling: root.scaling

            text: MediaService.getTrackDisplay()
            color: MediaService.getColor()
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
            TooltipService.hide();
        }
    }
}
