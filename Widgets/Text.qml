import QtQuick

import "../Commons"

Text {
    property real scaling: 1.0

    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
    color: Settings.data.colors.mOnSurface
}
