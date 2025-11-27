import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property string label: ""
  property string description: ""
  property bool enabled: true
  property bool checked: false
  property bool hovering: false

  // === Sizing ===
  // baseSize controls overall toggle scale. Components derive dimensions locally.
  // Default: Style.baseWidgetSize * 0.8 gives around 32px track height at default scale
  property real baseSize: QsCommons.Style.baseWidgetSize * 0.8 * QsCommons.Style.uiScaleRatio

  // Local dimensions
  readonly property real trackWidth: Math.round(baseSize * 1.625)    
  readonly property real trackHeight: Math.round(baseSize)           
  readonly property real thumbChecked: Math.round(baseSize * 0.75)   
  readonly property real thumbUnchecked: Math.round(baseSize * 0.5)  
  readonly property real thumbPadding: Math.round(baseSize * 0.125)  

  // === Signals ===
  signal toggled(bool checked)
  signal entered
  signal exited

  Layout.fillWidth: true
  opacity: enabled ? QsCommons.Style.opacityFull : QsCommons.Style.opacityDisabled

  QsComponents.CLabel {
    label: root.label
    description: root.description
  }

  Rectangle {
    id: switcher
    implicitWidth: root.trackWidth
    implicitHeight: root.trackHeight
    radius: QsCommons.Style.radiusRound
    
    color: root.checked ? QsCommons.Color.mPrimary : QsCommons.Color.mSurfaceVariant
    border.color: QsCommons.Color.mOutline
    border.width: root.checked ? QsCommons.Style.borderNone : QsCommons.Style.borderM

    Behavior on color {
      ColorAnimation {
        duration: QsCommons.Style.animationFast
      }
    }

    Behavior on border.width {
      NumberAnimation {
        duration: QsCommons.Style.animationFast
      }
    }

    Rectangle {
      id: thumb
      
      implicitWidth: root.checked ? root.thumbChecked : root.thumbUnchecked
      implicitHeight: root.checked ? root.thumbChecked : root.thumbUnchecked
      radius: QsCommons.Style.radiusRound
      
      color: root.checked ? QsCommons.Color.mOnPrimary : QsCommons.Color.mOutline
      border.width: QsCommons.Style.borderNone
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? switcher.width - width - root.thumbPadding : root.thumbPadding

      Behavior on x {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
      
      Behavior on implicitWidth {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
      
      Behavior on implicitHeight {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      
      onEntered: {
        if (!enabled)
          return
        hovering = true
        root.entered()
      }
      
      onExited: {
        if (!enabled)
          return
        hovering = false
        root.exited()
      }
      
      onClicked: {
        if (!enabled)
          return
        root.toggled(!root.checked)
      }
    }
  }
}
