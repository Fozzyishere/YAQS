import QtQuick

import qs.Commons
import qs.Services
import qs.Widgets

Item {
    id: root

    // ===== Properties =====
    property var screen: null
    property real scaling: 1.0

    // ===== Visibility =====
    visible: NetworkService.isEnabled || NetworkService.isConnected

    // Auto-size to content
    implicitWidth: barPill.implicitWidth
    implicitHeight: barPill.implicitHeight

    // ===== Bar Pill Component =====
    BarPill {
        id: barPill
        anchors.fill: parent
        scaling: root.scaling

        icon: NetworkService.getIcon()
        text: NetworkService.getStatusText()
        iconColor: NetworkService.getColor()
        textColor: NetworkService.getColor()

        tooltipText: {
            if (!NetworkService.isEnabled) {
                return "WiFi Disabled"
            } else if (!NetworkService.isConnected) {
                return "WiFi: Not Connected"
            } else {
                return "Connected to: " + NetworkService.ssid + "\nSignal: " + NetworkService.signalStrength + "%"
            }
        }

        clickable: true

        onClicked: {
            // Placeholder for future panel integration
            Logger.log("WiFi", "Widget clicked - panel integration coming soon")
        }
    }
}