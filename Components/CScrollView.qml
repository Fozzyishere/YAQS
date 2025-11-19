import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "../Commons" as QsCommons

T.ScrollView {
  id: root

  // === Public Properties ===
  property color handleColor: Qt.alpha(QsCommons.Color.mTertiary, 0.8)
  property color handleHoverColor: handleColor
  property color handlePressedColor: handleColor
  property color trackColor: QsCommons.Color.transparent
  property real handleWidth: 6 * QsCommons.Style.uiScaleRatio
  property real handleRadius: QsCommons.Style.radiusXS
  property int verticalPolicy: ScrollBar.AsNeeded
  property int horizontalPolicy: ScrollBar.AsNeeded
  property bool preventHorizontalScroll: horizontalPolicy === ScrollBar.AlwaysOff
  property int boundsBehavior: Flickable.StopAtBounds
  property int flickableDirection: Flickable.VerticalFlick

  implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, contentWidth + leftPadding + rightPadding)
  implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, contentHeight + topPadding + bottomPadding)

  // === Initialization ===
  Component.onCompleted: {
    configureFlickable()
  }

  // === Functions ===
  function configureFlickable() {
    // Find the internal Flickable (it's usually the first child)
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (child.toString().indexOf("Flickable") !== -1) {
        // Configure the flickable to prevent horizontal scrolling
        child.boundsBehavior = root.boundsBehavior
        
        // TODO: Hack, will fix later
        // Configure faster rebound animation (3x faster)
        child.flickDeceleration = 15000  // Default is 5000, 3x faster = 15000
        child.rebound = Qt.createQmlObject('
          import QtQuick 2.0
          Transition {
            NumberAnimation {
              properties: "x,y"
              duration: 50
              easing.type: Easing.OutBounce
            }
          }
        ', child)

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
    parent: root
    x: root.mirrored ? 0 : root.width - width
    y: root.topPadding
    height: root.availableHeight
    active: root.ScrollBar.horizontal.active
    policy: root.verticalPolicy

    contentItem: Rectangle {
      implicitWidth: root.handleWidth
      implicitHeight: 100
      radius: root.handleRadius
      color: parent.pressed ? root.handlePressedColor : parent.hovered ? root.handleHoverColor : root.handleColor
      opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 1.0 : 0.0

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
      implicitWidth: root.handleWidth
      implicitHeight: 100
      color: root.trackColor
      opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 0.3 : 0.0
      radius: root.handleRadius / 2

      Behavior on opacity {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }
  }

  ScrollBar.horizontal: ScrollBar {
    parent: root
    x: root.leftPadding
    y: root.height - height
    width: root.availableWidth
    active: root.ScrollBar.vertical.active
    policy: root.horizontalPolicy

    contentItem: Rectangle {
      implicitWidth: 100
      implicitHeight: root.handleWidth
      radius: root.handleRadius
      color: parent.pressed ? root.handlePressedColor : parent.hovered ? root.handleHoverColor : root.handleColor
      opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 1.0 : 0.0

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
      implicitHeight: root.handleWidth
      color: root.trackColor
      opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 0.3 : 0.0
      radius: root.handleRadius / 2

      Behavior on opacity {
        NumberAnimation {
          duration: QsCommons.Style.animationFast
        }
      }
    }
  }
}
