import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "../Commons" as QsCommons

T.ScrollView {
  id: root

  // === Public Properties ===
  property color handleColor: Qt.alpha(QsCommons.Color.mTertiary, 0.8)
  property color handleHoverColor: QsCommons.Color.mPrimary
  property color handlePressedColor: QsCommons.Color.mPrimary
  property color trackColor: QsCommons.Color.transparent
  property int verticalPolicy: ScrollBar.AsNeeded
  property int horizontalPolicy: ScrollBar.AsNeeded
  property bool preventHorizontalScroll: horizontalPolicy === ScrollBar.AlwaysOff
  property int boundsBehavior: Flickable.StopAtBounds
  property int flickableDirection: Flickable.VerticalFlick

  // === Sizing ===
  readonly property real handleWidthNormal: Math.round(4 * QsCommons.Style.uiScaleRatio)
  readonly property real handleWidthExpanded: Math.round(8 * QsCommons.Style.uiScaleRatio)

  implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, contentWidth + leftPadding + rightPadding)
  implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, contentHeight + topPadding + bottomPadding)

  // === Initialization ===
  Component.onCompleted: {
    configureFlickable()
  }

  // === Rebound Transition (defined as component for cleaner code) ===
  Transition {
    id: fastReboundTransition
    NumberAnimation {
      properties: "x,y"
      duration: 50  // 3x faster than default 150ms
      easing.type: Easing.OutBounce
    }
  }

  // === Functions ===
  function configureFlickable() {
    // Find the internal Flickable (ScrollView doesn't expose it directly)
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (child.toString().indexOf("Flickable") !== -1) {
        child.boundsBehavior = root.boundsBehavior
        child.flickDeceleration = 15000  // 3x faster than default 5000
        child.rebound = fastReboundTransition

        if (root.preventHorizontalScroll) {
          child.flickableDirection = Flickable.VerticalFlick
          child.contentWidth = Qt.binding(() => child.width)
        } else {
          child.flickableDirection = root.flickableDirection
        }
        break
      }
    }
  }

  // Watch for changes in horizontalPolicy
  onHorizontalPolicyChanged: {
    preventHorizontalScroll = (horizontalPolicy === ScrollBar.AlwaysOff)
    configureFlickable()
  }

  // === Scrollbars ===
  ScrollBar.vertical: ScrollBar {
    id: verticalScrollBar
    parent: root
    x: root.mirrored ? 0 : root.width - width
    y: root.topPadding
    height: root.availableHeight
    active: root.ScrollBar.horizontal.active
    policy: root.verticalPolicy

    contentItem: Rectangle {
      id: verticalHandle
      
      // Expand on hover (4px → 8px)
      implicitWidth: verticalScrollBar.hovered || verticalScrollBar.pressed 
        ? root.handleWidthExpanded 
        : root.handleWidthNormal
      implicitHeight: 100
      
      radius: implicitWidth / 2
      
      // Color changes on interaction
      color: verticalScrollBar.pressed 
        ? root.handlePressedColor 
        : verticalScrollBar.hovered 
          ? root.handleHoverColor 
          : root.handleColor
      
      opacity: verticalScrollBar.policy === ScrollBar.AlwaysOn || verticalScrollBar.active ? 1.0 : 0.0

      Behavior on implicitWidth {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }

    background: Rectangle {
      implicitWidth: root.handleWidthExpanded
      implicitHeight: 100
      color: root.trackColor
      opacity: verticalScrollBar.policy === ScrollBar.AlwaysOn || verticalScrollBar.active ? 0.2 : 0.0
      radius: implicitWidth / 2  // Pill-shaped track

      Behavior on opacity {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }
  }

  ScrollBar.horizontal: ScrollBar {
    id: horizontalScrollBar
    parent: root
    x: root.leftPadding
    y: root.height - height
    width: root.availableWidth
    active: root.ScrollBar.vertical.active
    policy: root.horizontalPolicy

    contentItem: Rectangle {
      id: horizontalHandle
      
      // Expand on hover (4px → 8px)
      implicitWidth: 100
      implicitHeight: horizontalScrollBar.hovered || horizontalScrollBar.pressed 
        ? root.handleWidthExpanded 
        : root.handleWidthNormal
      
      radius: implicitHeight / 2
      
      // Color changes on interaction
      color: horizontalScrollBar.pressed 
        ? root.handlePressedColor 
        : horizontalScrollBar.hovered 
          ? root.handleHoverColor 
          : root.handleColor
      
      opacity: horizontalScrollBar.policy === ScrollBar.AlwaysOn || horizontalScrollBar.active ? 1.0 : 0.0

      Behavior on implicitHeight {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }

    background: Rectangle {
      implicitWidth: 100
      implicitHeight: root.handleWidthExpanded
      color: root.trackColor
      opacity: horizontalScrollBar.policy === ScrollBar.AlwaysOn || horizontalScrollBar.active ? 0.2 : 0.0
      radius: implicitHeight / 2  // Pill-shaped track

      Behavior on opacity {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }
  }
}
