import QtQuick
import QtQuick.Controls
import "../Commons" as QsCommons
import "../Components" as QsComponents

TextField {
  id: root

  property bool clearButtonEnabled: false

  implicitWidth: 200 * QsCommons.Style.uiScaleRatio
  implicitHeight: QsCommons.Style.baseWidgetSize * 1.1 * QsCommons.Style.uiScaleRatio

  font.family: QsCommons.Settings.data.ui.fontDefault
  font.pointSize: QsCommons.Style.fontSizeM * QsCommons.Style.uiScaleRatio
  color: QsCommons.Color.mOnSurface
  selectByMouse: true
  leftPadding: QsCommons.Style.marginM
  rightPadding: clearButtonEnabled ? clearButton.width + QsCommons.Style.marginM : QsCommons.Style.marginM
  topPadding: 0
  bottomPadding: 0
  
  verticalAlignment: TextInput.AlignVCenter

  background: Rectangle {
    radius: QsCommons.Style.radiusS
    
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
    baseSize: QsCommons.Style.baseWidgetSize * 0.6
    
    onClicked: {
      root.text = ""
      root.forceActiveFocus()
    }
  }
}
