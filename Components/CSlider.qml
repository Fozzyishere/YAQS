import QtQuick
import QtQuick.Controls
import "../Commons" as QsCommons
import "../Services" as QsServices

Slider {
  id: root

  property var cutoutColor: QsCommons.Color.mSurface
  property bool snapAlways: true
  property real heightRatio: 0.7
  property string tooltipText
  property string tooltipDirection: "auto"
  property bool hovering: false

  readonly property real knobDiameter: Math.round((QsCommons.Style.baseWidgetSize * heightRatio * QsCommons.Style.uiScaleRatio) / 2) * 2
  readonly property real trackHeight: Math.round((knobDiameter * 0.4 * QsCommons.Style.uiScaleRatio) / 2) * 2
  readonly property real cutoutExtra: Math.round((QsCommons.Style.baseWidgetSize * 0.1 * QsCommons.Style.uiScaleRatio) / 2) * 2

  padding: cutoutExtra / 2

  snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
  implicitHeight: Math.max(trackHeight, knobDiameter)

  background: Rectangle {
    x: root.leftPadding
    y: root.topPadding + root.availableHeight / 2 - height / 2
    implicitWidth: QsCommons.Style.sliderWidth
    implicitHeight: trackHeight
    width: root.availableWidth
    height: implicitHeight
    radius: height / 2
    
    color: Qt.alpha(QsCommons.Color.mSurface, 0.5)
    border.color: Qt.alpha(QsCommons.Color.mOutline, 0.5)
    border.width: QsCommons.Style.borderS

    // === Active Track ===
    Item {
      id: activeTrackContainer
      width: root.visualPosition * parent.width
      height: parent.height

      // Rounded end cap
      Rectangle {
        width: parent.height
        height: parent.height
        radius: width / 2
        color: Qt.darker(QsCommons.Color.mPrimary, 1.2)
      }

      // Main gradient rectangle
      Rectangle {
        x: parent.height / 2
        width: parent.width - x
        height: parent.height
        radius: 0
        
        // Animated gradient fill
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop {
            position: 0.0
            color: Qt.darker(QsCommons.Color.mPrimary, 1.2)
            Behavior on color {
              ColorAnimation {
                duration: 300
              }
            }
          }
          GradientStop {
            position: 0.5
            color: QsCommons.Color.mPrimary
            SequentialAnimation on position {
              loops: Animation.Infinite
              NumberAnimation {
                from: 0.3
                to: 0.7
                duration: 2000
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                from: 0.7
                to: 0.3
                duration: 2000
                easing.type: Easing.InOutSine
              }
            }
          }
          GradientStop {
            position: 1.0
            color: Qt.lighter(QsCommons.Color.mPrimary, 1.2)
          }
        }
      }
    }

    // === Cutout ===
    Rectangle {
      id: knobCutout
      implicitWidth: knobDiameter + cutoutExtra
      implicitHeight: knobDiameter + cutoutExtra
      radius: width / 2  // Keep circular cutout
      color: root.cutoutColor !== undefined ? root.cutoutColor : QsCommons.Color.mSurface
      x: root.leftPadding + root.visualPosition * (root.availableWidth - root.knobDiameter) - cutoutExtra / 2
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  handle: Item {
    implicitWidth: knobDiameter
    implicitHeight: knobDiameter
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      id: knob
      implicitWidth: knobDiameter
      implicitHeight: knobDiameter
      radius: QsCommons.Style.radiusXS
      
      color: root.pressed ? QsCommons.Color.mTertiary : QsCommons.Color.mSurface
      border.color: QsCommons.Color.mPrimary
      border.width: QsCommons.Style.borderL  // 3px emphasis border
      anchors.centerIn: parent

      Behavior on color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }

    MouseArea {
      enabled: true
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      // Pass through mouse events to the slider
      propagateComposedEvents: true
      preventStealing: false

      onEntered: {
        root.hovering = true
        if (root.tooltipText) {
          QsServices.TooltipService.show(Screen, knob, root.tooltipText, root.tooltipDirection)
        }
      }

      onExited: {
        root.hovering = false
        if (root.tooltipText) {
          QsServices.TooltipService.hide()
        }
      }

      onPressed: function (mouse) {
        if (root.tooltipText) {
          QsServices.TooltipService.hide()
        }
        // Pass the event through to the slider
        mouse.accepted = false
      }

      onReleased: function (mouse) {
        // Pass the event through to the slider
        mouse.accepted = false
      }

      onPositionChanged: function (mouse) {
        // Pass the event through to the slider
        mouse.accepted = false
      }
    }
  }
}
