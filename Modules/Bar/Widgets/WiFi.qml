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
    visible: NetworkService.isEnabled || NetworkService.isConnected
    spacing: Math.round(Theme.spacing_xs * scaling)

    // ===== Icon =====
    Text {
        text: NetworkService.getIcon()
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(Theme.icon_size * scaling)
        color: NetworkService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Theme.duration_normal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Status Text =====
    Text {
        text: NetworkService.getStatusText()
        font.family: Theme.font_family
        font.pixelSize: Math.round(Theme.font_size * scaling)
        color: NetworkService.getColor()

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: Theme.duration_normal
                easing.type: Easing.InOutCubic
            }
        }
    }

    // ===== Interaction =====
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        // Click action
        onClicked: {
            // Placeholder for future panel integration
            Logger.log("WiFi", "Widget clicked - panel integration coming soon");
        }

        // Tooltip
        onEntered: {
            let tooltipText = "";
            if (!NetworkService.isEnabled) {
                tooltipText = "WiFi Disabled";
            } else if (!NetworkService.isConnected) {
                tooltipText = "WiFi: Not Connected";
            } else {
                tooltipText = "Connected to: " + NetworkService.ssid + "\nSignal: " + NetworkService.signalStrength + "%";
            }
            TooltipService.show(root, tooltipText, 500);
        }

        onExited: {
            TooltipService.hide();
        }
    }
}