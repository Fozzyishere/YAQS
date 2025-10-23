import QtQuick

import qs.Commons
import qs.Services
import qs.Widgets

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
    implicitWidth: barPill.implicitWidth
    implicitHeight: barPill.implicitHeight

    // ===== Bar Pill Component =====
    BarPill {
        id: barPill
        anchors.fill: parent
        scaling: root.scaling

        icon: BrightnessService.getIcon()
        text: BrightnessService.brightness
        suffix: "%"
        iconColor: BrightnessService.getColor()
        textColor: BrightnessService.getColor()

        showText: showPercentage
        showTextOnHover: displayMode === "onhover"
        tooltipText: "Brightness: " + BrightnessService.brightness + "%\nScroll to adjust"

        acceptWheel: true
        clickable: false

        onWheel: function(delta) {
            wheelAccumulator += delta

            // One notch = 120 units
            if (wheelAccumulator >= 120) {
                wheelAccumulator = 0
                BrightnessService.increaseBrightness(5)  // +5%
            } else if (wheelAccumulator <= -120) {
                wheelAccumulator = 0
                BrightnessService.decreaseBrightness(5)  // -5%
            }
        }
    }
}