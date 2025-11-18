import QtQuick
import "../Commons" as QsCommons

// Rounded container primitive using surface variant background.
// Used in panels and settings to group related elements.
Rectangle {
  id: root

  // === Dimensions ===
  implicitWidth: childrenRect.width
  implicitHeight: childrenRect.height

  // === Appearance ===
  color: QsCommons.Color.mSurfaceVariant
  radius: QsCommons.Style.radiusM
  border.color: QsCommons.Color.mOutline
  border.width: QsCommons.Style.borderS
}
