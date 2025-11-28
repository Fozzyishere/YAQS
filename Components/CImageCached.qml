import QtQuick
import "../Commons" as QsCommons
import "../Components" as QsComponents

Item {
  id: root

  // === Public Properties ===
  property alias source: image.source
  property alias status: image.status
  property alias sourceSize: image.sourceSize
  property alias fillMode: image.fillMode
  property alias smooth: image.smooth
  property alias mipmap: image.mipmap
  property alias asynchronous: image.asynchronous
  property alias cache: image.cache

  // Custom properties
  property bool showLoadingIndicator: true
  property bool showErrorState: true
  property color backgroundColor: QsCommons.Color.mSurfaceContainerLow
  property color errorColor: QsCommons.Color.mErrorContainer

  // === Sizing ===
  implicitWidth: image.implicitWidth > 0 ? image.implicitWidth : 100
  implicitHeight: image.implicitHeight > 0 ? image.implicitHeight : 100

  // Background for loading/error states
  Rectangle {
    id: background
    anchors.fill: parent
    color: image.status === Image.Error ? root.errorColor : root.backgroundColor
    visible: image.status !== Image.Ready
    radius: 0  // Let parent handle radius
  }

  // Main image
  Image {
    id: image
    anchors.fill: parent
    cache: true
    asynchronous: true
    smooth: true
    fillMode: Image.PreserveAspectFit

    // Fade in when loaded
    opacity: status === Image.Ready ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: QsCommons.Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }
  }

  // Loading indicator
  QsComponents.CBusyIndicator {
    anchors.centerIn: parent
    indicatorSize: Math.min(root.width, root.height) * 0.4
    running: image.status === Image.Loading && root.showLoadingIndicator
    visible: running
    color: QsCommons.Color.mPrimary
  }

  // Error state
  Item {
    anchors.fill: parent
    visible: image.status === Image.Error && root.showErrorState

    QsComponents.CIcon {
      anchors.centerIn: parent
      icon: "photo-off"
      pointSize: Math.min(root.width, root.height) * 0.3
      color: QsCommons.Color.mOnErrorContainer
    }
  }
}

