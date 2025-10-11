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
    visible: BatteryService.hasBattery
    spacing: Math.round(Settings.data.ui.spacingXs * scaling)

    // ===== Icon =====
    Text {
        text: BatteryService.getIcon()
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(Settings.data.ui.iconSize * scaling)
        color: BatteryService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Settings.data.ui.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Percentage =====
    Text {
        text: BatteryService.batteryPercent + "%"
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        color: BatteryService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Settings.data.ui.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }
}
