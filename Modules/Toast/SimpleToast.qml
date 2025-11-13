// MVP FOR TESTING PURPOSES ONLY, WILL BE REPLACED SOON!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// --- IGNORE ---


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Commons" as QsCommons
import "../../Services" as QsServices

Rectangle {
  id: root

  property var notification: null
  property string notificationId: ""
  readonly property real initialScale: 0.7

  signal dismissed(string notifId)

  width: parent.width
  height: Math.round(contentLayout.implicitHeight + QsCommons.Style.marginL * 2)
  radius: QsCommons.Style.radiusL
  visible: false
  opacity: 0
  scale: initialScale
  color: QsCommons.Color.mSurface

  // Colored border based on urgency
  border.color: {
    if (!notification) return QsCommons.Color.mOutline
    
    switch (notification.urgency) {
    case 2: // Critical
      return QsCommons.Color.mError
    case 0: // Low
      return QsCommons.Color.mOutline
    default: // Normal
      return QsCommons.Color.mPrimary
    }
  }
  border.width: Math.max(2, QsCommons.Style.borderM)

  // Smooth fade in/out animation
  Behavior on opacity {
    NumberAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  // Smooth scale (zoom) animation
  Behavior on scale {
    NumberAnimation {
      duration: QsCommons.Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  // Watch notification progress to auto-dismiss
  Timer {
    interval: 50
    running: notification !== null && visible
    repeat: true
    onTriggered: {
      if (notification && notification.progress !== undefined && notification.progress <= 0) {
        root.hide()
      }
    }
  }

  // Animation completion timer
  Timer {
    id: hideAnimation
    interval: QsCommons.Style.animationFast
    onTriggered: {
      root.visible = false
      root.dismissed(root.notificationId)
    }
  }

  // Cleanup on destruction
  Component.onDestruction: {
    hideAnimation.stop()
  }

  RowLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: QsCommons.Style.marginL
    spacing: QsCommons.Style.marginL

    // App icon or urgency indicator
    Text {
      id: urgencyIndicator
      text: {
        if (!notification) return "ℹ"
        
        switch (notification.urgency) {
        case 2: return "✖"  // Critical
        case 0: return "ℹ"  // Low
        default: return "⚠"  // Normal
        }
      }
      color: {
        if (!notification) return QsCommons.Color.mOnSurface
        
        switch (notification.urgency) {
        case 2: return QsCommons.Color.mError
        case 0: return QsCommons.Color.mOnSurface
        default: return QsCommons.Color.mPrimary
        }
      }
      font.pixelSize: QsCommons.Style.fontSizeXXL * 1.5
      Layout.alignment: Qt.AlignVCenter
    }

    // Summary and body
    ColumnLayout {
      spacing: QsCommons.Style.marginXXS
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter

      Text {
        Layout.fillWidth: true
        text: notification ? (notification.summary || "") : ""
        color: QsCommons.Color.mOnSurface
        font.pixelSize: QsCommons.Style.fontSizeL
        font.weight: Font.Bold
        wrapMode: Text.WordWrap
        visible: text.length > 0
      }

      Text {
        Layout.fillWidth: true
        text: notification ? (notification.body || "") : ""
        color: QsCommons.Color.mOnSurface
        font.pixelSize: QsCommons.Style.fontSizeM
        wrapMode: Text.WordWrap
        visible: text.length > 0
        textFormat: Text.PlainText  // Ignore markup for now
      }
    }
  }

  // Click anywhere to dismiss
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    onClicked: {
      // Dismiss the notification in NotificationService
      if (notification && notification.id !== undefined) {
        QsServices.NotificationService.dismissActiveNotification(notification.id)
      }
      root.hide()
    }
    cursorShape: Qt.PointingHandCursor
  }

  // Show notification with fade-in and scale animation
  function showNotification(notif) {
    // Stop animation timer first
    hideAnimation.stop()

    notification = notif
    notificationId = notif.id

    visible = true
    opacity = 1
    scale = 1.0
  }

  // Hide notification with fade-out and scale animation
  function hide() {
    opacity = 0
    scale = initialScale
    hideAnimation.restart()
  }
}
