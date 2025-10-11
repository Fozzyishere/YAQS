import QtQuick
import QtQuick.Layouts

import "../../../Commons"
import "../../../Services"

RowLayout {
    id: root

    // ===== Properties =====
    property var screen: null
    property real scaling: 1.0

    // ===== Visibility =====
    visible: BrightnessService.isAvailable
    spacing: Math.round(Settings.data.ui.spacingXs * scaling)

    // Wheel scroll accumulator
    property int wheelAccumulator: 0

    // ===== Icon =====
    Text {
        text: BrightnessService.getIcon()
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(Settings.data.ui.iconSize * scaling)
        color: BrightnessService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Settings.data.ui.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Brightness Percentage =====
    Text {
        text: BrightnessService.brightness + "%"
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        color: BrightnessService.getColor()

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
        acceptedButtons: Qt.NoButton  // Only wheel scroll, no click

        // Wheel scroll
        onWheel: function(wheel) {
            wheelAccumulator += wheel.angleDelta.y;

            // One notch = 120 units
            if (wheelAccumulator >= 120) {
                wheelAccumulator = 0;
                BrightnessService.increaseBrightness(5);  // +5%
                wheel.accepted = true;
            } else if (wheelAccumulator <= -120) {
                wheelAccumulator = 0;
                BrightnessService.decreaseBrightness(5);  // -5%
                wheel.accepted = true;
            }
        }

        cursorShape: Qt.PointingHandCursor

        // Tooltip
        onEntered: {
            TooltipService.show(root, "Brightness: " + BrightnessService.brightness + "%\nScroll to adjust", 500);
        }

        onExited: {
            TooltipService.hide();
        }
    }
}