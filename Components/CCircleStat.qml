import QtQuick
import "../Commons" as QsCommons
import "../Components" as QsComponents

Item {
  id: root

  // === Public Properties ===
  property real value: 0  // 0-100
  property real maximum: 100
  property string label: ""
  property bool showValue: true
  property bool showPercent: true
  property color primaryColor: QsCommons.Color.mPrimary
  property color trackColor: QsCommons.Color.mSurfaceContainerHigh

  // === Sizing (Self-contained) ===
  property real size: QsCommons.Style.baseWidgetSize * 3 * QsCommons.Style.uiScaleRatio
  property real lineWidth: Math.round(6 * QsCommons.Style.uiScaleRatio)

  implicitWidth: size
  implicitHeight: size

  // Computed values
  readonly property real progress: Math.min(Math.max(value / maximum, 0), 1)
  readonly property real displayValue: Math.round(value)

  // Background track
  Canvas {
    id: backgroundTrack
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.lineWidth = root.lineWidth
      ctx.strokeStyle = root.trackColor
      ctx.lineCap = "round"

      var centerX = width / 2
      var centerY = height / 2
      var radius = (width - root.lineWidth) / 2

      ctx.beginPath()
      ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
      ctx.stroke()
    }
  }

  // Progress arc
  Canvas {
    id: progressArc
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.lineWidth = root.lineWidth
      ctx.strokeStyle = root.primaryColor
      ctx.lineCap = "round"

      var centerX = width / 2
      var centerY = height / 2
      var radius = (width - root.lineWidth) / 2

      // Start from top (-90 degrees)
      var startAngle = -Math.PI / 2
      var endAngle = startAngle + (root.progress * 2 * Math.PI)

      ctx.beginPath()
      ctx.arc(centerX, centerY, radius, startAngle, endAngle)
      ctx.stroke()
    }

    // Repaint when progress changes
    Connections {
      target: root
      function onProgressChanged() {
        progressArc.requestPaint()
      }
    }
  }

  // Value display
  Column {
    anchors.centerIn: parent
    spacing: QsCommons.Style.marginXXS
    visible: root.showValue

    QsComponents.CText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.showPercent ? root.displayValue + "%" : root.displayValue.toString()
      pointSize: root.size * 0.2
      font.weight: QsCommons.Style.fontWeightBold
      color: root.primaryColor
    }

    QsComponents.CText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.label
      pointSize: root.size * 0.1
      color: QsCommons.Color.mOnSurfaceVariant
      visible: root.label !== ""
    }
  }

  // Initial paint
  Component.onCompleted: {
    backgroundTrack.requestPaint()
    progressArc.requestPaint()
  }
}

