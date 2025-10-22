import QtQuick
import QtQuick.Layouts

import "../../../Commons"

RowLayout {
    id: root

    // Standard widget properties
    property var screen: null
    property real scaling: 1.0

    // Metadata and settings support (optional - passed by BarWidgetLoader)
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property var widgetMetadata: ({})
    property var widgetSettings: ({})

    readonly property string timeFormat: widgetSettings.timeFormat ?? widgetMetadata.timeFormat ?? "hh:mm AP"
    readonly property string dateFormat: widgetSettings.dateFormat ?? widgetMetadata.dateFormat ?? "dddd, MMM d yyyy"
    readonly property bool showTime: widgetSettings.showTime ?? widgetMetadata.showTime ?? true
    readonly property bool showDate: widgetSettings.showDate ?? widgetMetadata.showDate ?? true

    spacing: Math.round(Settings.data.ui.spacingS * scaling)

    // Time
    Text {
        visible: showTime
        text: Qt.formatTime(Time.current, timeFormat)
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        color: Settings.data.colors.mOnSurface
    }

    // Separator
    Rectangle {
        visible: showTime && showDate
        width: 1
        height: Math.round(Settings.data.bar.height * 0.5 * scaling)
        color: Settings.data.colors.mOutlineVariant
        opacity: 0.3
    }

    // Date
    Text {
        visible: showDate
        text: Qt.formatDate(Time.current, dateFormat)
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        color: Settings.data.colors.mOnSurface
    }
}
