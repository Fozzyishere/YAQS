import QtQuick
import QtQuick.Layouts
import "../Commons" as QsCommons
import "../Components" as QsComponents

ColumnLayout {
  id: root

  // === Properties ===
  property string label: ""
  property string description: ""
  property bool expanded: false
  property bool defaultExpanded: false
  property real contentSpacing: QsCommons.Style.marginM
  signal toggled(bool expanded)

  Layout.fillWidth: true
  spacing: 0

  // === Default Content ===
  default property alias content: contentLayout.children

  // === Header ===
  Rectangle {
    id: headerContainer
    Layout.fillWidth: true
    Layout.preferredHeight: headerContent.implicitHeight + (QsCommons.Style.marginS * 2) 

    // Use mSurfaceContainer variants for elevation hierarchy
    color: root.expanded ? QsCommons.Color.mPrimaryContainer : QsCommons.Color.mSurfaceContainer
    radius: QsCommons.Style.radiusM  // 16px (MD3)

    // No explicit borders - rely on color contrast
    border.width: 0

    // Smooth color transitions
    Behavior on color {
      ColorAnimation {
        duration: QsCommons.Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: headerArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true

      onPressed: {
        root.expanded = !root.expanded
        root.toggled(root.expanded)
      }

      // 8% state layer for hover
      Rectangle {
        anchors.fill: parent
        color: QsCommons.Color.mOnSurface
        opacity: headerArea.containsMouse ? QsCommons.Style.opacityHover : 0
        radius: headerContainer.radius

        Behavior on opacity {
          NumberAnimation {
            duration: QsCommons.Style.animationFast
          }
        }
      }
    }

    RowLayout {
      id: headerContent
      anchors.fill: parent
      anchors.margins: QsCommons.Style.marginS
      spacing: QsCommons.Style.marginM

      // Expand/collapse icon with rotation animation
      QsComponents.CIcon {
        id: chevronIcon
        icon: "chevron-right"
        pointSize: QsCommons.Style.fontSizeL
        color: root.expanded ? QsCommons.Color.mOnPrimaryContainer : QsCommons.Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignVCenter

        rotation: root.expanded ? 90 : 0
        Behavior on rotation {
          NumberAnimation {
            duration: QsCommons.Style.animationNormal
            easing.type: Easing.OutCubic
          }
        }

        Behavior on color {
          ColorAnimation {
            duration: QsCommons.Style.animationNormal
          }
        }
      }

      // Header text content - properly contained
      RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: QsCommons.Style.marginL

        QsComponents.CText {
          text: root.label
          pointSize: QsCommons.Style.fontSizeL
          font.weight: QsCommons.Style.fontWeightSemiBold
          color: root.expanded ? QsCommons.Color.mOnPrimaryContainer : QsCommons.Color.mOnSurface
          wrapMode: Text.WordWrap

          Behavior on color {
            ColorAnimation {
              duration: QsCommons.Style.animationNormal
            }
          }
        }

        QsComponents.CText {
          text: root.description
          pointSize: QsCommons.Style.fontSizeS
          font.weight: QsCommons.Style.fontWeightRegular
          color: root.expanded ? QsCommons.Color.mOnPrimaryContainer : QsCommons.Color.mOnSurfaceVariant
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
          visible: root.description !== ""
          opacity: QsCommons.Style.opacityHigh

          Behavior on color {
            ColorAnimation {
              duration: QsCommons.Style.animationNormal
            }
          }
        }
      }
    }
  }

  // === Collapsible Content (MD3 v2.0: No borders, use elevation) ===
  Rectangle {
    id: contentContainer
    Layout.fillWidth: true
    Layout.topMargin: QsCommons.Style.marginXS

    clip: true  // Clip content during collapse animation
    
    // Use mSurfaceContainerLow for lower elevation than header
    color: QsCommons.Color.mSurfaceContainerLow
    radius: QsCommons.Style.radiusM  // 16px (MD3)
    
    // No explicit borders
    border.width: 0

    // Start with 0 height, will be animated
    Layout.preferredHeight: 0

    // Content layout
    ColumnLayout {
      id: contentLayout
      anchors.fill: parent
      anchors.margins: QsCommons.Style.marginM
      spacing: root.contentSpacing
      opacity: 0
    }

    // Use states for explicit control
    states: [
      State {
        name: "expanded"
        when: root.expanded
        PropertyChanges {
          target: contentContainer
          Layout.preferredHeight: contentLayout.implicitHeight + (QsCommons.Style.marginM * 2)
        }
        PropertyChanges {
          target: contentLayout
          opacity: 1.0
        }
      },
      State {
        name: "collapsed"
        when: !root.expanded
        PropertyChanges {
          target: contentContainer
          Layout.preferredHeight: 0
        }
        PropertyChanges {
          target: contentLayout
          opacity: 0
        }
      }
    ]

    // Explicit transitions for smooth animations
    transitions: [
      // Expanding: fade in content, then expand height
      Transition {
        from: "collapsed"
        to: "expanded"
        SequentialAnimation {
          NumberAnimation {
            target: contentLayout
            property: "opacity"
            duration: QsCommons.Style.animationFast
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: contentContainer
            property: "Layout.preferredHeight"
            duration: QsCommons.Style.animationFast
            easing.type: Easing.OutCubic
          }
        }
      },
      // Collapsing: shrink height and fade simultaneously, with opacity finishing first
      Transition {
        from: "expanded"
        to: "collapsed"
        ParallelAnimation {
          NumberAnimation {
            target: contentLayout
            property: "opacity"
            duration: 100  // Very fast fade
            easing.type: Easing.InCubic
          }
          NumberAnimation {
            target: contentContainer
            property: "Layout.preferredHeight"
            duration: QsCommons.Style.animationFast
            easing.type: Easing.InOutCubic
          }
        }
      }
    ]
  }

  // === Initialization ===
  Component.onCompleted: {
    root.expanded = root.defaultExpanded
  }
}