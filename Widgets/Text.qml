import QtQuick

import "../Commons"

Text {
  property real scaling: 1.0

  font.family: Theme.font_family
  font.pixelSize: Math.round(Theme.font_size * scaling)
  color: Theme.fg
}
