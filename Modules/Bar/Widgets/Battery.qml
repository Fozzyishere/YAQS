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
    spacing: Math.round(Theme.spacing_xs * scaling)

    // ===== Icon =====
    Text {
        text: BatteryService.getIcon()
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(Theme.icon_size * scaling)
        color: BatteryService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Theme.duration_normal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Percentage =====
    Text {
        text: BatteryService.batteryPercent + "%"
        font.family: Theme.font_family
        font.pixelSize: Math.round(Theme.font_size * scaling)
        color: BatteryService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Theme.duration_normal
                easing.type: Easing.InOutCubic
            }
        }
    }
}
