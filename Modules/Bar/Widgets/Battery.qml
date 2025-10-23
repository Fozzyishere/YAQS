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
    spacing: Math.round(Style.spacingXs * scaling)

    // ===== Icon =====
    Text {
        text: BatteryService.getIcon()
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(Style.iconSize * scaling)
        color: BatteryService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Style.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Percentage =====
    Text {
        text: BatteryService.batteryPercent + "%"
        font.family: Style.fontFamily
        font.pixelSize: Math.round(Style.fontSize * scaling)
        color: BatteryService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Style.durationNormal
                easing.type: Easing.InOutCubic
            }
        }
    }
}
