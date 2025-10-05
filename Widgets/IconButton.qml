import QtQuick

import "../Commons"

Rectangle {
    id: root

    // Public properties
    property string icon: ""
    property int size: Theme.icon_size
    property color iconColor: Theme.fg
    property real scaling: 1.0

    // Signals
    signal clicked

    // Internal properties
    property bool _hovered: false

    // Dimensions
    implicitWidth: Math.round((size + Theme.spacing_s * 2) * scaling)
    implicitHeight: Math.round((size + Theme.spacing_s * 2) * scaling)

    // Appearance
    color: _hovered ? Theme.bg_hover : "transparent"
    radius: Theme.radius_s

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
            duration: Theme.duration_fast
        }
    }
}
