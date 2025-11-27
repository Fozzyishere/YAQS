import QtQuick
import QtQuick.Controls
import "../Commons" as QsCommons
import "../Components" as QsComponents

TextField {
  id: root

  // === Public Properties ===
  property bool clearButtonEnabled: false

  // === Sizing ===
  // baseSize controls overall input scale
  property real baseSize: QsCommons.Style.baseWidgetSize * 1.4 * QsCommons.Style.uiScaleRatio

  // Local dimensions
  readonly property real inputHeight: Math.round(baseSize)
  readonly property real inputWidth: Math.round(200 * QsCommons.Style.uiScaleRatio)
  readonly property real clearButtonSize: Math.round(baseSize * 0.43)

  implicitWidth: inputWidth
  implicitHeight: inputHeight

  font.family: QsCommons.Settings.data.ui.fontDefault
  font.pointSize: QsCommons.Style.fontSizeM * QsCommons.Style.uiScaleRatio
  color: QsCommons.Color.mOnSurface
  selectByMouse: true
  leftPadding: QsCommons.Style.marginS
  rightPadding: clearButtonEnabled ? clearButton.width + QsCommons.Style.marginS : QsCommons.Style.marginS
  // No padding. Magic number should be fine for now unless padding is agressively used in the future.
  topPadding: 0
  bottomPadding: 0
  
  verticalAlignment: TextInput.AlignVCenter

  background: Rectangle {
    radius: QsCommons.Style.radiusXS
    
    color: QsCommons.Color.mSurfaceVariant
    border.color: root.activeFocus ? QsCommons.Color.mPrimary : QsCommons.Color.mOutline
    border.width: root.activeFocus ? QsCommons.Style.borderM : QsCommons.Style.borderS
    
    Behavior on border.color {
      ColorAnimation { duration: QsCommons.Style.animationFast }
    }
    
    Behavior on border.width {
      NumberAnimation { duration: QsCommons.Style.animationFast }
    }
  }

  placeholderTextColor: QsCommons.Color.mOnSurfaceVariant

  QsComponents.CIconButton {
    id: clearButton
    visible: clearButtonEnabled && root.text !== ""
    anchors.right: parent.right
    anchors.rightMargin: QsCommons.Style.marginXS
    anchors.verticalCenter: parent.verticalCenter
    icon: "x"
    baseSize: root.clearButtonSize
    shouldApplyUiScale: false  // Already scaled via root.baseSize
    
    onClicked: {
      root.text = ""
      root.forceActiveFocus()
    }
  }
}
