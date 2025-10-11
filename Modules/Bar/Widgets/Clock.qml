import QtQuick
import QtQuick.Layouts

import "../../../Commons"

RowLayout {
    id: root

    property var screen: null
    property real scaling: 1.0

    spacing: Math.round(Settings.data.ui.spacingS * scaling)

    // Time
    Text {
        text: Qt.formatTime(Time.current, "hh:mm AP")
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        color: Settings.data.colors.mOnSurface
    }

    // Separator
    Rectangle {
        width: 1
        height: Math.round(Settings.data.bar.height * 0.5 * scaling)
        color: Settings.data.colors.mOutlineVariant
        opacity: 0.3
    }

    // Date
    Text {
        text: Qt.formatDate(Time.current, "dddd, MMM d yyyy")
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        color: Settings.data.colors.mOnSurface
    }
}
