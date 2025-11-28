import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "../Commons" as QsCommons

Item {
  id: root

  // === Public Properties ===
  property color handleColor: Qt.alpha(QsCommons.Color.mTertiary, 0.8)
  property color handleHoverColor: QsCommons.Color.mPrimary
  property color handlePressedColor: QsCommons.Color.mPrimary
  property color trackColor: QsCommons.Color.transparent
  property int verticalPolicy: ScrollBar.AsNeeded
  property int horizontalPolicy: ScrollBar.AsNeeded

  // === Sizing ===
  // Pill-shaped scrollbars that expand on hover (4px → 8px)
  // Self-contained sizing per styling architecture
  readonly property real handleWidthNormal: Math.round(4 * QsCommons.Style.uiScaleRatio)
  readonly property real handleWidthExpanded: Math.round(8 * QsCommons.Style.uiScaleRatio)
  readonly property real defaultSize: Math.round(200 * QsCommons.Style.uiScaleRatio)

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
  property alias header: listView.header
  property alias footer: listView.footer
  property alias highlight: listView.highlight

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
  implicitWidth: defaultSize
  implicitHeight: defaultSize

  // === Internal ListView ===
  ListView {
    id: listView
    anchors.fill: parent

    // Enable clipping to keep content within bounds
    clip: true

    // Enable flickable for smooth scrolling
    boundsBehavior: Flickable.DragAndOvershootBounds
    
    // Control overscroll rebound speed (3x faster for snappy feel)
    flickDeceleration: 15000  // Default is 5000
    rebound: Transition {
      NumberAnimation {
        properties: "x,y"
        duration: 50  // Default is 150ms
        easing.type: Easing.OutBounce
      }
    }

    // === Scrollbars ===
    ScrollBar.vertical: ScrollBar {
      id: verticalScrollBar
      parent: listView
      x: listView.mirrored ? 0 : listView.width - width
      y: 0
      height: listView.height
      active: listView.ScrollBar.horizontal.active
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
      parent: listView
      x: 0
      y: listView.height - height
      width: listView.width
      active: listView.ScrollBar.vertical.active
      policy: root.horizontalPolicy

      contentItem: Rectangle {
        id: horizontalHandle
        
        // Expand on hover (4px → 8px)
        implicitWidth: 100
        implicitHeight: horizontalScrollBar.hovered || horizontalScrollBar.pressed 
          ? root.handleWidthExpanded 
          : root.handleWidthNormal
        
        // Pill-shaped (fully rounded)
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
}
