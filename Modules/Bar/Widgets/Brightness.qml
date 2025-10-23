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

    // ===== Visibility =====
    visible: BrightnessService.isAvailable

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
            text: BrightnessService.getIcon()
            font.family: "Symbols Nerd Font"
            font.pixelSize: Math.round(Style.iconSize * scaling)
            color: BrightnessService.getColor()

            // Smooth color transitions
            Behavior on color {
                ColorAnimation {
                    duration: Style.durationNormal
                    easing.type: Easing.InOutCubic
                }
            }
        }

        // ===== Brightness Percentage =====
        Text {
            visible: showPercentage
            text: BrightnessService.brightness + "%"
            font.family: Style.fontFamily
            font.pixelSize: Math.round(Style.fontSize * scaling)
            color: BrightnessService.getColor()

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