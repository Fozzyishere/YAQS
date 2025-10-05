import QtQuick

import "../Commons"

Rectangle {
  id: root

  // Public properties
  property string text: ""
  property bool active: false
  property color textColor: Theme.fg
  property real scaling: 1.0

  // Signals
  signal clicked()

  // Internal properties
  property bool _hovered: false

  // Dimensions
  implicitWidth: Math.round((label.implicitWidth + Theme.spacing_m * 2) * scaling)
  implicitHeight: Math.round((Theme.bar_height - Theme.spacing_s) * scaling)

  // Background color
  color: {
    if (active) {
      // Active: semi-transparent color overlay
      return Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.2)
    }
    if (_hovered) {
      // Hovered: bg_hover
      return Theme.bg_hover
    }
    // Normal: transparent
    return "transparent"
  }

  radius: Theme.radius_s

  // Label
  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    color: root.textColor
    font.family: Theme.font_family
    font.pixelSize: Math.round(Theme.font_size * scaling)
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
      duration: Theme.duration_normal
    }
  }
}