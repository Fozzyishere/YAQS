import QtQuick
import QtQuick.Layouts

import "../../../Commons"
import "../../../Services"

Item {
    id: root

    // ===== Standard widget properties =====
    property var screen: null
    property real scaling: 1.0

    // ===== Metadata and settings support =====
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property var widgetMetadata: ({})
    property var widgetSettings: ({})

    // Settings resolution: user settings → metadata defaults → hardcoded fallback
    readonly property string displayMode: widgetSettings.displayMode ?? widgetMetadata.displayMode ?? "onhover"
    readonly property bool showPercentage: widgetSettings.showPercentage ?? widgetMetadata.showPercentage ?? true

    // ===== Internal properties =====
    property int wheelAccumulator: 0

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
            id: iconText
            text: AudioService.getIcon()
            font.family: "Symbols Nerd Font"
            font.pixelSize: Math.round(Style.iconSize * scaling)
            color: AudioService.getColor()

            // Smooth color transitions
            Behavior on color {
                ColorAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.InOutCubic
                }
            }
        }

        // ===== Volume percentage =====
        Text {
            visible: showPercentage
            text: AudioService.volume + "%"
            font.family: Style.fontFamily
            font.pixelSize: Math.round(Style.fontSize * scaling)
            color: AudioService.getColor()

            // Smooth color transitions
            Behavior on color {
                ColorAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.InOutCubic
                }
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
