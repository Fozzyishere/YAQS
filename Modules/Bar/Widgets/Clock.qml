import QtQuick
import QtQuick.Layouts

import "../../../Commons"

RowLayout {
    id: root

    property var screen: null
    property real scaling: 1.0

    spacing: Math.round(Theme.spacing_s * scaling)

    // Time
    Text {
        text: Qt.formatTime(Time.current, "hh:mm AP")
        font.family: Theme.font_family
        font.pixelSize: Math.round(Theme.font_size * scaling)
        color: Theme.fg
    }

    // Separator
    Rectangle {
        width: 1
        height: Math.round(Theme.bar_height * 0.5 * scaling)
        color: Theme.fg_dim
        opacity: 0.3
    }

    // Date
    Text {
        text: Qt.formatDate(Time.current, "dddd, MMM d yyyy")
        font.family: Theme.font_family
        font.pixelSize: Math.round(Theme.font_size * scaling)
        color: Theme.fg
    }
}
