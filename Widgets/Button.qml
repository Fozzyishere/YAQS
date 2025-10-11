import QtQuick

import "../Commons"

Rectangle {
    id: root

    // Public properties
    property string text: ""
    property bool active: false
    property color textColor: Settings.data.colors.mOnSurface
    property real scaling: 1.0

    // Signals
    signal clicked

    // Internal properties
    property bool _hovered: false

    // Dimensions
    implicitWidth: Math.round((label.implicitWidth + Settings.data.ui.spacingM * 2) * scaling)
    implicitHeight: Math.round((Settings.data.bar.height - Settings.data.ui.spacingS) * scaling)

    // Background color
    color: {
        if (active) {
            // Active: semi-transparent color overlay
            return Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.2);
        }
        if (_hovered) {
            // Hovered: bg1
            return Settings.data.colors.mSurfaceVariant;
        }
        // Normal: transparent
        return "transparent";
    }

    radius: Settings.data.ui.radiusS

    // Label
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
        font.weight: root.active ? Font.Medium : Font.Normal
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
            duration: Settings.data.ui.durationNormal
        }
    }
}
