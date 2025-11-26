import QtQuick
import "../Commons" as QsCommons

// Rounded container primitive with MD3 surface background.
// No border by default - relies on color contrast for definition.
Rectangle {
  id: root

  // === Public Properties ===
  property bool hasBorder: false  // MD3: borders optional, off by default

  // === Dimensions ===
  implicitWidth: childrenRect.width
  implicitHeight: childrenRect.height

  // === Appearance ===
  color: QsCommons.Color.mSurfaceContainer
  radius: QsCommons.Style.radiusM
  border.width: hasBorder ? QsCommons.Style.borderS : 0
  border.color: hasBorder ? QsCommons.Color.mOutline : "transparent"
}
