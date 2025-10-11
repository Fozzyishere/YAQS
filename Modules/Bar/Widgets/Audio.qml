import QtQuick
import QtQuick.Layouts

import "../../../Commons"
import "../../../Services"

RowLayout {
    id: root

    // ===== Properties =====
    property var screen: null
    property real scaling: 1.0

    // ===== State =====
    spacing: Math.round(Settings.data.ui.spacingXs * scaling)

    // Wheel scroll accumulator
    property int wheelAccumulator: 0

    // ===== Icon =====
    Text {
        id: iconText
        text: AudioService.getIcon()
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(Settings.data.ui.iconSize * scaling)
        color: AudioService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Settings.data.ui.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Volume percentage =====
    Text {
        text: AudioService.volume + "%"
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        color: AudioService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Settings.data.ui.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Interaction =====
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        // Click to toggle mute
        onClicked: {
            AudioService.toggleMute();
        }

        // Wheel scroll to change volume
        onWheel: function(wheel) {
            wheelAccumulator += wheel.angleDelta.y;

            // One notch = 120 units
            if (wheelAccumulator >= 120) {
                wheelAccumulator = 0;
                AudioService.increaseVolume(5);  // +5%
                wheel.accepted = true;
            } else if (wheelAccumulator <= -120) {
                wheelAccumulator = 0;
                AudioService.decreaseVolume(5);  // -5%
                wheel.accepted = true;
            }
        }

        cursorShape: Qt.PointingHandCursor
    }
}
