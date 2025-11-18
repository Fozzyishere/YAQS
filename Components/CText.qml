import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons

Text {
  id: root

  // === Public Properties ===
  property string family: QsCommons.Settings.data.ui.fontDefault
  property real pointSize: QsCommons.Style.fontSizeM
  property bool applyUiScale: true
  property real fontScale: {
    const fontScale = (root.family === QsCommons.Settings.data.ui.fontDefault ? QsCommons.Settings.data.ui.fontDefaultScale : QsCommons.Settings.data.ui.fontFixedScale)
    if (applyUiScale) {
      return fontScale * QsCommons.Style.uiScaleRatio
    }
    return fontScale
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
