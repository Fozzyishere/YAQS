import QtQuick
import "../Commons" as QsCommons
import "../Components" as QsComponents

Rectangle {
  id: root

  // === Public Properties ===
  property int count: 0
  property int maxCount: 99
  property bool showZero: false
  property bool dot: false  // Show as dot without count
  property color badgeColor: QsCommons.Color.mError
  property color textColor: QsCommons.Color.mOnError

  // === Sizing (Self-contained) ===
  readonly property real baseSize: Math.round(18 * QsCommons.Style.uiScaleRatio)
  readonly property real dotSize: Math.round(8 * QsCommons.Style.uiScaleRatio)
  readonly property real minWidth: dot ? dotSize : baseSize
  readonly property real padding: QsCommons.Style.marginXXS

  // Computed display value
  readonly property string displayText: count > maxCount ? maxCount + "+" : count.toString()

  // Visibility logic
  visible: dot || count > 0 || showZero

  // MD3: Pill-shaped badge
  implicitWidth: dot ? dotSize : Math.max(minWidth, textItem.implicitWidth + padding * 2)
  implicitHeight: dot ? dotSize : baseSize
  radius: height / 2  // Fully rounded (pill)

  color: badgeColor

  // Count text
  QsComponents.CText {
    id: textItem
    anchors.centerIn: parent
    text: root.displayText
    pointSize: QsCommons.Style.fontSizeXS
    font.weight: QsCommons.Style.fontWeightSemiBold
    color: root.textColor
    visible: !root.dot
  }

  // Animation for count changes
  Behavior on implicitWidth {
    NumberAnimation {
      duration: QsCommons.Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  // Pop animation when count increases
  SequentialAnimation {
    id: popAnimation

    NumberAnimation {
      target: root
      property: "scale"
      to: 1.2
      duration: 100
      easing.type: Easing.OutQuad
    }

    NumberAnimation {
      target: root
      property: "scale"
      to: 1.0
      duration: 150
      easing.type: Easing.OutBounce
    }
  }

  // Trigger pop animation on count increase
  onCountChanged: {
    if (count > 0) {
      popAnimation.start()
    }
  }
}

