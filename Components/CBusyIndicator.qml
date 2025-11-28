import QtQuick
import "../Commons" as QsCommons

Item {
  id: root

  // === Public Properties ===
  property bool running: true
  property color color: QsCommons.Color.mPrimary
  property real lineWidth: Math.round(3 * QsCommons.Style.uiScaleRatio)

  // === Sizing (Self-contained) ===
  property real indicatorSize: QsCommons.Style.baseWidgetSize * QsCommons.Style.uiScaleRatio

  implicitWidth: indicatorSize
  implicitHeight: indicatorSize

  // Background track (subtle)
  Rectangle {
    id: backgroundTrack
    anchors.centerIn: parent
    width: root.indicatorSize
    height: root.indicatorSize
    radius: width / 2
    color: QsCommons.Color.transparent
    border.color: Qt.alpha(root.color, 0.15)
    border.width: root.lineWidth
  }

  // Spinning arc indicator
  Canvas {
    id: spinner
    anchors.centerIn: parent
    width: root.indicatorSize
    height: root.indicatorSize

    // Arc properties animated for the stretch/contract effect
    property real headPosition: 0    
    property real tailPosition: 0    

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.lineWidth = root.lineWidth
      ctx.strokeStyle = root.color
      ctx.lineCap = "round"

      var centerX = width / 2
      var centerY = height / 2
      var radius = (width - root.lineWidth) / 2

      // Ensure minimum arc length for visibility
      var arcLength = headPosition - tailPosition
      if (arcLength < 0.1) arcLength = 0.1

      ctx.beginPath()
      ctx.arc(centerX, centerY, radius, tailPosition, tailPosition + arcLength)
      ctx.stroke()
    }

    onHeadPositionChanged: requestPaint()
    onTailPositionChanged: requestPaint()
  }

  SequentialAnimation {
    id: spinnerAnimation
    running: root.running
    loops: Animation.Infinite

    // Arc expands - head moves fast, tail moves slow
    ParallelAnimation {
      NumberAnimation {
        target: spinner
        property: "headPosition"
        from: 0.1 * Math.PI
        to: 1.5 * Math.PI
        duration: 750
        easing.type: Easing.InOutCubic
      }
      NumberAnimation {
        target: spinner
        property: "tailPosition"
        from: 0
        to: 0.5 * Math.PI
        duration: 750
        easing.type: Easing.InOutCubic
      }
    }

    // Arc contracts - head slows, tail catches up
    ParallelAnimation {
      NumberAnimation {
        target: spinner
        property: "headPosition"
        from: 1.5 * Math.PI
        to: 2.1 * Math.PI
        duration: 750
        easing.type: Easing.InOutCubic
      }
      NumberAnimation {
        target: spinner
        property: "tailPosition"
        from: 0.5 * Math.PI
        to: 2 * Math.PI
        duration: 750
        easing.type: Easing.InOutCubic
      }
    }

    // Reset positions
    ScriptAction {
      script: {
        spinner.headPosition = 0.1 * Math.PI
        spinner.tailPosition = 0
      }
    }
  }

  // Rotation underneath the stretch/contract animation
  RotationAnimator on rotation {
    from: 0
    to: 360
    duration: 2000
    loops: Animation.Infinite
    running: root.running
  }
}
