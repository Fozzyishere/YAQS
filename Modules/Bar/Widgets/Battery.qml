import QtQuick

import "../../../Commons"
import "../../../Services"
import "../../../Widgets"

Item {
    id: root

    // ===== Properties =====
    property var screen: null
    property real scaling: 1.0

    // ===== State =====
    visible: BatteryService.hasBattery

    // Auto-size to content
    implicitWidth: iconText.implicitWidth
    implicitHeight: iconText.implicitHeight

    // ===== Icon + Text Component =====
    IconText {
        id: iconText
        anchors.fill: parent
        scaling: root.scaling

        icon: BatteryService.getIcon()
        text: BatteryService.batteryPercent + "%"
        iconColor: BatteryService.getColor()
        textColor: BatteryService.getColor()
    }
}
