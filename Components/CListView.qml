import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "../Commons" as QsCommons

Item {
  id: root

  // === Public Properties ===
  property color handleColor: Qt.alpha(QsCommons.Color.mTertiary, 0.8)
  property color handleHoverColor: handleColor
  property color handlePressedColor: handleColor
  property color trackColor: QsCommons.Color.transparent
  property real handleWidth: 6 * QsCommons.Style.uiScaleRatio
  property real handleRadius: QsCommons.Style.radiusXS  // YAQS CHANGE: 2px (was radiusM = 8px)
  property int verticalPolicy: ScrollBar.AsNeeded
  property int horizontalPolicy: ScrollBar.AsNeeded

  // === Forwarded ListView Properties ===
  property alias model: listView.model
  property alias delegate: listView.delegate
  property alias spacing: listView.spacing
  property alias orientation: listView.orientation
  property alias currentIndex: listView.currentIndex
  property alias count: listView.count
  property alias contentHeight: listView.contentHeight
  property alias contentWidth: listView.contentWidth
  property alias contentY: listView.contentY
  property alias contentX: listView.contentX
  property alias currentItem: listView.currentItem
  property alias highlightItem: listView.highlightItem
  property alias headerItem: listView.headerItem
  property alias footerItem: listView.footerItem
  property alias section: listView.section
  property alias highlightFollowsCurrentItem: listView.highlightFollowsCurrentItem
  property alias highlightMoveDuration: listView.highlightMoveDuration
  property alias highlightMoveVelocity: listView.highlightMoveVelocity
  property alias preferredHighlightBegin: listView.preferredHighlightBegin
  property alias preferredHighlightEnd: listView.preferredHighlightEnd
  property alias highlightRangeMode: listView.highlightRangeMode
  property alias snapMode: listView.snapMode
  property alias keyNavigationWraps: listView.keyNavigationWraps
  property alias cacheBuffer: listView.cacheBuffer
  property alias displayMarginBeginning: listView.displayMarginBeginning
  property alias displayMarginEnd: listView.displayMarginEnd
  property alias layoutDirection: listView.layoutDirection
  property alias effectiveLayoutDirection: listView.effectiveLayoutDirection
  property alias verticalLayoutDirection: listView.verticalLayoutDirection
  property alias boundsBehavior: listView.boundsBehavior
  property alias flickableDirection: listView.flickableDirection
  property alias interactive: listView.interactive
  property alias moving: listView.moving
  property alias flicking: listView.flicking
  property alias dragging: listView.dragging
  property alias horizontalVelocity: listView.horizontalVelocity
  property alias verticalVelocity: listView.verticalVelocity

  // === Forwarded ListView Methods ===
  function positionViewAtIndex(index, mode) {
    listView.positionViewAtIndex(index, mode)
  }

  function positionViewAtBeginning() {
    listView.positionViewAtBeginning()
  }

  function positionViewAtEnd() {
    listView.positionViewAtEnd()
  }

  function forceLayout() {
    listView.forceLayout()
  }

  function cancelFlick() {
    listView.cancelFlick()
  }

  function flick(xVelocity, yVelocity) {
    listView.flick(xVelocity, yVelocity)
  }

  function incrementCurrentIndex() {
    listView.incrementCurrentIndex()
  }

  function decrementCurrentIndex() {
    listView.decrementCurrentIndex()
  }

  function indexAt(x, y) {
    return listView.indexAt(x, y)
  }

  function itemAt(x, y) {
    return listView.itemAt(x, y)
  }

  function itemAtIndex(index) {
    return listView.itemAtIndex(index)
  }

  // Set reasonable implicit sizes for Layout usage
  implicitWidth: 200 * QsCommons.Style.uiScaleRatio
  implicitHeight: 200 * QsCommons.Style.uiScaleRatio

  // === Internal ListView ===
  ListView {
    id: listView
    anchors.fill: parent

    // Enable clipping to keep content within bounds
    clip: true

    // Enable flickable for smooth scrolling
    boundsBehavior: Flickable.DragAndOvershootBounds
    
    //TODO: Hack since flick animation in qtquick is weird. Will fix later
    // Control overscroll rebound speed (3x faster)
    flickDeceleration: 15000  // Default is 5000, 3x faster = 15000. 
    rebound: Transition {
      NumberAnimation {
        properties: "x,y"
        duration: 50  // Default is 150ms, 3x faster = 50ms
        easing.type: Easing.OutBounce
      }
    }

    // === Scrollbars ===
    ScrollBar.vertical: ScrollBar {
      parent: listView
      x: listView.mirrored ? 0 : listView.width - width
      y: 0
      height: listView.height
      active: listView.ScrollBar.horizontal.active
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
      id: horizontalScrollBar
      parent: listView
      x: 0
      y: listView.height - height
      width: listView.width
      active: listView.ScrollBar.vertical.active
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
}
