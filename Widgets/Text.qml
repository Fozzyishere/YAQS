import QtQuick

import "../Commons"

Text {
    property real scaling: 1.0

    font.family: Style.fontFamily
    font.pixelSize: Math.round(Style.fontSize * scaling)
    color: Color.mOnSurface
}
