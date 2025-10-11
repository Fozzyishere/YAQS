import QtQuick

import "../Commons"

Rectangle {
    id: root

    // Public properties
    property string icon: ""
    property int size: Settings.data.ui.iconSize
    property color iconColor: Settings.data.colors.mOnSurface
    property real scaling: 1.0

    // Signals
    signal clicked

    // Internal properties
    property bool _hovered: false

    // Dimensions
    implicitWidth: Math.round((size + Settings.data.ui.spacingS * 2) * scaling)
    implicitHeight: Math.round((size + Settings.data.ui.spacingS * 2) * scaling)

    // Appearance
    color: _hovered ? Settings.data.colors.mSurfaceVariant : "transparent"
    radius: Settings.data.ui.radiusS

    // Icon
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Math.round(root.size * root.scaling)
        color: root.iconColor
    }

    // Mouse interaction
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
        onEntered: root._hovered = true
        onExited: root._hovered = false
    }

    // Color transition
    Behavior on color {
        ColorAnimation {
            duration: Settings.data.ui.durationFast
        }
    }
}
