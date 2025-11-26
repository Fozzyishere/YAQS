import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons

// Base text component with font scaling and eliding.
Text {
  id: root

  // === Public Properties ===
  property string family: QsCommons.Settings.data.ui.fontDefault
  property real pointSize: QsCommons.Style.fontSizeM
  property bool shouldApplyUiScale: true

  // === Readonly Properties ===
  readonly property real fontScale: {
    const scale = (root.family === QsCommons.Settings.data.ui.fontDefault
      ? QsCommons.Settings.data.ui.fontDefaultScale
      : QsCommons.Settings.data.ui.fontFixedScale)
    return shouldApplyUiScale ? scale * QsCommons.Style.uiScaleRatio : scale
  }

  // === Appearance ===
  font.family: root.family
  font.weight: QsCommons.Style.fontWeightMedium
  font.pointSize: root.pointSize * fontScale
  color: QsCommons.Color.mOnSurface
  elide: Text.ElideRight
  wrapMode: Text.NoWrap
  verticalAlignment: Text.AlignVCenter
}
