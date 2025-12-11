import QtQuick
import QtQuick.Layouts
import "../../Commons" as QsCommons
import "../../Services" as QsServices
import "../../Components" as QsComponents

// Individual notification card with:
// - Swipe left/right to dismiss (simple horizontal slide)
// - Right-click to dismiss
// - Hover/drag to pause timeout
// - Progress bar visualization
// - Entry/exit animations
// - Inline reply support
// - Keyboard navigation (Escape to dismiss)
Item {
  id: root

  // === Required Properties ===
  required property string notificationId
  required property var notificationData
  required property real cardWidth
  required property real swipeOverflow
  required property bool isTop
  property int animationDelay: 0

  // === Computed Properties (safe access) ===
  readonly property string appName: notificationData?.appName ?? "Unknown"
  readonly property string summary: notificationData?.summary ?? ""
  readonly property string body: notificationData?.body ?? ""
  readonly property int urgency: notificationData?.urgency ?? 1
  readonly property real progress: notificationData?.progress ?? 1
  readonly property string originalImage: notificationData?.originalImage ?? ""
  readonly property string actionsJson: notificationData?.actionsJson ?? "[]"
  readonly property bool hasInlineReply: notificationData?.hasInlineReply ?? false
  readonly property string inlineReplyPlaceholder: notificationData?.inlineReplyPlaceholder ?? "Reply..."
  readonly property var timestamp: notificationData?.timestamp ?? new Date()

  // === Layout ===
  Layout.preferredWidth: cardWidth + swipeOverflow * 2
  Layout.preferredHeight: displayContainer.height
  Layout.alignment: Qt.AlignHCenter

  // === Swipe State ===
  property real dragX: 0
  property bool isDragging: false
  property bool isRemoving: false
  readonly property real dismissThreshold: cardWidth * 0.35

  // === Interaction Tracking (hover + drag pauses timeout) ===
  property int hoverCount: 0
  readonly property bool shouldPauseTimeout: hoverCount > 0 || isDragging

  onShouldPauseTimeoutChanged: {
    if (notificationId === "") return
    if (shouldPauseTimeout) {
      resumeTimer.stop()
      QsServices.NotificationService.pauseTimeout(notificationId)
    } else {
      resumeTimer.start()
    }
  }

  Timer {
    id: resumeTimer
    interval: 50
    onTriggered: {
      if (!root.shouldPauseTimeout && root.notificationId !== "") {
        QsServices.NotificationService.resumeTimeout(root.notificationId)
      }
    }
  }

  // === Cached Formatted Time ===
  property string formattedTime: ""

  Timer {
    id: timeUpdateTimer
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.formattedTime = QsCommons.Time.formatRelativeTime(root.timestamp)
  }

  // === Animation Properties ===
  property real scaleValue: 0.8
  property real opacityValue: 0.0
  property real slideOffset: isTop ? -200 : 200

  // === Entry Animation ===
  Component.onCompleted: {
    if (QsCommons.Settings.data.general?.animationDisabled) {
      slideOffset = 0
      scaleValue = 1.0
      opacityValue = 1.0
    } else {
      entryDelayTimer.interval = Math.max(1, animationDelay)
      entryDelayTimer.start()
    }
  }

  Timer {
    id: entryDelayTimer
    onTriggered: {
      root.slideOffset = 0
      root.scaleValue = 1.0
      root.opacityValue = 1.0
    }
  }

  // === Exit Animation ===
  function animateOut() {
    if (isRemoving) return
    isRemoving = true

    if (!QsCommons.Settings.data.general?.animationDisabled) {
      if (Math.abs(dragX) > 10) {
        dragX = dragX > 0 ? cardWidth + swipeOverflow : -(cardWidth + swipeOverflow)
      } else {
        slideOffset = isTop ? -200 : 200
      }
      opacityValue = 0.0
    }
  }

  Timer {
    id: removalTimer
    interval: QsCommons.Style.animationSlow
    running: isRemoving
    onTriggered: {
      if (root.notificationId !== "") {
        QsServices.NotificationService.dismissActiveNotification(root.notificationId)
      }
    }
  }

  // === Animation Behaviors ===
  Behavior on scaleValue {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    SpringAnimation { spring: 3; damping: 0.4 }
  }

  Behavior on opacityValue {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    NumberAnimation { duration: QsCommons.Style.animationNormal; easing.type: Easing.OutCubic }
  }

  Behavior on slideOffset {
    enabled: !QsCommons.Settings.data.general?.animationDisabled
    SpringAnimation { spring: 2.5; damping: 0.35 }
  }

  Behavior on dragX {
    enabled: !isDragging && !isRemoving
    SpringAnimation { spring: 4; damping: 0.5 }
  }

  // === Keyboard Navigation ===
  focus: true
  Keys.onEscapePressed: animateOut()
  Keys.onReturnPressed: {
    try {
      const actions = JSON.parse(root.actionsJson)
      if (actions.length > 0 && root.notificationId !== "") {
        QsServices.NotificationService.invokeAction(root.notificationId, actions[0].identifier)
      }
    } catch (e) {}
  }

  // === Display Container ===
  Item {
    id: displayContainer
    clip: false
    width: parent.width
    height: card.height + QsCommons.Style.marginS * 2
    y: slideOffset

    opacity: opacityValue
    scale: scaleValue

    // === The Actual Card ===
    Rectangle {
      id: card
      width: cardWidth
      height: cardContent.implicitHeight + QsCommons.Style.marginL * 2

      x: swipeOverflow + dragX
      y: QsCommons.Style.marginS

      radius: QsCommons.Style.radiusL
      color: QsCommons.Color.mSurface
      border.color: QsCommons.Color.mOutline
      border.width: QsCommons.Style.borderS

      // === Progress Bar ===
      Rectangle {
        id: progressBar
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property real availableWidth: parent.width - parent.radius * 2
        width: availableWidth * root.progress
        height: 2

        color: {
          if (root.urgency === 2) return QsCommons.Color.mError
          if (root.urgency === 0) return QsCommons.Color.mOnSurfaceVariant
          return QsCommons.Color.mPrimary
        }

        visible: !QsCommons.Settings.data.general?.animationDisabled

        Behavior on width {
          enabled: !isRemoving && !QsCommons.Settings.data.general?.animationDisabled
          NumberAnimation { duration: 100; easing.type: Easing.Linear }
        }
      }

      // === Drag Handler (Swipe Gesture) ===
      DragHandler {
        id: dragHandler
        target: null
        xAxis.enabled: true
        yAxis.enabled: false

        onActiveChanged: {
          isDragging = active

          if (!active && !isRemoving) {
            if (Math.abs(dragX) > dismissThreshold) {
              animateOut()
            } else {
              dragX = 0
            }
          }
        }

        onTranslationChanged: {
          if (active) {
            dragX = translation.x
          }
        }
      }

      // === Mouse Area (Hover + Right-Click) ===
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton

        onEntered: hoverCount++
        onExited: hoverCount--
        onClicked: mouse => {
          if (mouse.button === Qt.RightButton) {
            animateOut()
          }
        }
      }

      // === Card Content ===
      ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: QsCommons.Style.marginM
        anchors.rightMargin: QsCommons.Style.marginM + closeButton.width + QsCommons.Style.marginS
        spacing: QsCommons.Style.marginS

        // === Header Row ===
        RowLayout {
          Layout.fillWidth: true
          spacing: QsCommons.Style.marginS

          // Urgency indicator dot
          Rectangle {
            width: 6
            height: 6
            radius: 3
            color: {
              if (root.urgency === 2) return QsCommons.Color.mError
              if (root.urgency === 0) return QsCommons.Color.mOnSurfaceVariant
              return QsCommons.Color.mPrimary
            }
            Layout.alignment: Qt.AlignVCenter
          }

          QsComponents.CText {
            text: root.appName + " · " + root.formattedTime
            color: QsCommons.Color.mOnSurfaceVariant
            pointSize: Math.max(8, QsCommons.Style.fontSizeXS)
            textFormat: Text.PlainText
          }

          Item { Layout.fillWidth: true }
        }

        // === Main Content Row ===
        RowLayout {
          Layout.fillWidth: true
          spacing: QsCommons.Style.marginM

          // App icon with fallback
          Item {
            Layout.preferredWidth: Math.round(40 * QsCommons.Style.uiScaleRatio)
            Layout.preferredHeight: Math.round(40 * QsCommons.Style.uiScaleRatio)
            Layout.alignment: Qt.AlignTop

            QsComponents.CImageCircled {
              id: notificationImage
              anchors.fill: parent
              source: root.originalImage
              showBorder: false
              visible: status === Image.Ready && source !== ""
            }

            QsComponents.CIcon {
              anchors.centerIn: parent
              visible: !notificationImage.visible
              icon: "bell"
              pointSize: Math.max(12, QsCommons.Style.fontSizeXL)
              color: QsCommons.Color.mOnSurfaceVariant
            }
          }

          // Text content
          ColumnLayout {
            Layout.fillWidth: true
            spacing: QsCommons.Style.marginXS

            QsComponents.CText {
              text: root.summary
              pointSize: Math.max(10, QsCommons.Style.fontSizeL)
              font.weight: QsCommons.Style.fontWeightMedium
              color: QsCommons.Color.mOnSurface
              textFormat: Text.PlainText
              wrapMode: Text.WrapAtWordBoundaryOrAnywhere
              maximumLineCount: 2
              elide: Text.ElideRight
              Layout.fillWidth: true
              visible: root.summary.length > 0
            }

            QsComponents.CText {
              text: root.body
              pointSize: Math.max(10, QsCommons.Style.fontSizeM)
              color: QsCommons.Color.mOnSurface
              textFormat: Text.PlainText
              wrapMode: Text.WrapAtWordBoundaryOrAnywhere
              maximumLineCount: 4
              elide: Text.ElideRight
              Layout.fillWidth: true
              visible: root.body.length > 0
            }
          }
        }

        // === Action Buttons ===
        Flow {
          id: actionsFlow
          Layout.fillWidth: true
          Layout.topMargin: QsCommons.Style.marginS
          spacing: QsCommons.Style.marginS

          property var parsedActions: {
            try {
              return JSON.parse(root.actionsJson)
            } catch (e) {
              return []
            }
          }

          visible: parsedActions.length > 0

          Repeater {
            model: actionsFlow.parsedActions

            QsComponents.CButton {
              text: modelData.text ?? "Action"
              fontSize: Math.max(10, QsCommons.Style.fontSizeS)
              implicitHeight: 28
              isTonal: true

              onClicked: {
                if (root.notificationId !== "") {
                  QsServices.NotificationService.invokeAction(
                    root.notificationId,
                    modelData.identifier
                  )
                }
              }

              onEntered: hoverCount++
              onExited: hoverCount--
            }
          }
        }

        // === Inline Reply ===
        Loader {
          active: root.hasInlineReply
          Layout.fillWidth: true
          Layout.topMargin: QsCommons.Style.marginS

          sourceComponent: RowLayout {
            spacing: QsCommons.Style.marginS

            QsComponents.CTextInput {
              id: replyInput
              Layout.fillWidth: true
              placeholderText: root.inlineReplyPlaceholder

              onAccepted: {
                if (text.trim().length > 0 && root.notificationId !== "") {
                  QsServices.NotificationService.sendInlineReply(root.notificationId, text)
                  text = ""
                }
              }
            }

            QsComponents.CIconButton {
              icon: "send"
              isEnabled: replyInput.text.trim().length > 0
              tooltipText: "Send reply"
              onClicked: replyInput.accepted()

              onEntered: hoverCount++
              onExited: hoverCount--
            }
          }
        }
      }

      // === Close Button ===
      QsComponents.CIconButton {
        id: closeButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: QsCommons.Style.marginM

        icon: "x"
        baseSize: QsCommons.Style.baseWidgetSize * 0.6

        onClicked: animateOut()
        onEntered: hoverCount++
        onExited: hoverCount--
      }
    }
  }
}
