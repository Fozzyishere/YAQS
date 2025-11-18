import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons

Text {
  id: root

  // === Public Properties ===
  property string icon: QsCommons.Icons.defaultIcon
  property real pointSize: QsCommons.Style.fontSizeL
  property bool applyUiScale: true

  // === Appearance ===
  visible: (icon !== undefined) && (icon !== "")
  text: {
    if ((icon === undefined) || (icon === "")) {
      return ""
    }
    if (QsCommons.Icons.get(icon) === undefined) {
      QsCommons.Logger.w("Icon", `"${icon}"`, "doesn't exist in the icons font")
      QsCommons.Logger.callStack()
      return QsCommons.Icons.get(QsCommons.Icons.defaultIcon)
    }
    return QsCommons.Icons.get(icon)
  }
  font.family: QsCommons.Icons.fontFamily
  font.pointSize: applyUiScale ? root.pointSize * QsCommons.Style.uiScaleRatio : root.pointSize
  color: QsCommons.Color.mOnSurface
  verticalAlignment: Text.AlignVCenter
}
