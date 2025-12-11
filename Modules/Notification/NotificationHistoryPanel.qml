import QtQuick
import QtQuick.Layouts
import "../../Commons" as QsCommons
import "../../Services" as QsServices
import "../../Components" as QsComponents

// Notification history panel - CPanel-based scrollable list of past notifications
QsComponents.CPanel {
  id: root
  objectName: "notificationHistoryPanel"

  preferredWidth: Math.round(400 * QsCommons.Style.uiScaleRatio)
  preferredHeight: Math.round(500 * QsCommons.Style.uiScaleRatio)
  panelKeyboardFocus: true

  onOpened: QsServices.NotificationService.updateLastSeenTs()

  panelContent: Item {
    anchors.fill: parent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: QsCommons.Style.marginL
      spacing: QsCommons.Style.marginM

      // === Header ===
      RowLayout {
        Layout.fillWidth: true
        spacing: QsCommons.Style.marginM

        QsComponents.CIcon {
          icon: "bell"
          pointSize: QsCommons.Style.fontSizeXXL
          color: QsCommons.Color.mPrimary
        }

        QsComponents.CText {
          text: "Notifications"
          pointSize: QsCommons.Style.fontSizeL
          font.weight: QsCommons.Style.fontWeightBold
          Layout.fillWidth: true
        }

        // DND Toggle
        QsComponents.CIconButton {
          icon: QsCommons.Settings.data.notifications?.doNotDisturb
            ? "bell-off" : "bell"
          tooltipText: QsCommons.Settings.data.notifications?.doNotDisturb
            ? "Do Not Disturb: ON" : "Do Not Disturb: OFF"
          colorFg: QsCommons.Settings.data.notifications?.doNotDisturb
            ? QsCommons.Color.mError : QsCommons.Color.mOnSurfaceVariant
          onClicked: {
            QsCommons.Settings.data.notifications.doNotDisturb =
              !QsCommons.Settings.data.notifications.doNotDisturb
          }
        }

        // Clear All
        QsComponents.CIconButton {
          icon: "trash"
          tooltipText: "Clear all notifications"
          visible: QsServices.NotificationService.historyList.count > 0
          onClicked: {
            QsServices.NotificationService.clearHistory()
          }
        }

        // Close
        QsComponents.CIconButton {
          icon: "x"
          tooltipText: "Close"
          onClicked: root.close()
        }
      }

      QsComponents.CDivider {
        Layout.fillWidth: true
      }

      // === Empty State ===
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignCenter
        visible: QsServices.NotificationService.historyList.count === 0
        spacing: QsCommons.Style.marginL

        Item { Layout.fillHeight: true }

        QsComponents.CIcon {
          icon: "bell-off"
          pointSize: 64
          color: QsCommons.Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignHCenter
        }

        QsComponents.CText {
          text: "No notifications"
          pointSize: QsCommons.Style.fontSizeL
          color: QsCommons.Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignHCenter
        }

        QsComponents.CText {
          text: "Notifications will appear here"
          pointSize: QsCommons.Style.fontSizeS
          color: QsCommons.Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true }
      }

      // === History List ===
      QsComponents.CListView {
        id: historyList
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: QsServices.NotificationService.historyList.count > 0

        model: QsServices.NotificationService.historyList
        spacing: QsCommons.Style.marginS
        clip: true

        // Scrollbar configuration
        verticalPolicy: ScrollBar.AsNeeded
        horizontalPolicy: ScrollBar.AlwaysOff

        // Track expanded notification
        property string expandedId: ""

        delegate: Rectangle {
          id: historyCard

          property string notificationId: model.id
          property bool isExpanded: historyList.expandedId === notificationId

          width: historyList.width
          height: historyContent.implicitHeight + QsCommons.Style.marginM * 2
          radius: QsCommons.Style.radiusM
          color: QsCommons.Color.mSurfaceContainer
          border.color: Qt.alpha(QsCommons.Color.mOutline, 0.5)
          border.width: QsCommons.Style.borderS

          Behavior on height {
            enabled: !QsCommons.Settings.data.general?.animationDisabled
            NumberAnimation { duration: QsCommons.Style.animationNormal }
          }

          // Click to expand
          MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 48
            enabled: summaryText.truncated || bodyText.truncated
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              historyList.expandedId = isExpanded ? "" : notificationId
            }
          }

          RowLayout {
            id: historyContent
            anchors.fill: parent
            anchors.margins: QsCommons.Style.marginM
            spacing: QsCommons.Style.marginM

            // Icon with fallback
            Item {
              Layout.preferredWidth: Math.round(36 * QsCommons.Style.uiScaleRatio)
              Layout.preferredHeight: Math.round(36 * QsCommons.Style.uiScaleRatio)
              Layout.alignment: Qt.AlignTop

              QsComponents.CImageCircled {
                id: historyImage
                anchors.fill: parent
                source: model.cachedImage || model.originalImage || ""
                showBorder: false
                visible: status === Image.Ready && source !== ""
              }

              // Fallback icon when no image
              QsComponents.CIcon {
                anchors.centerIn: parent
                visible: !historyImage.visible
                icon: "bell"
                pointSize: QsCommons.Style.fontSizeL
                color: QsCommons.Color.mOnSurfaceVariant
              }
            }

            // Content
            ColumnLayout {
              Layout.fillWidth: true
              spacing: QsCommons.Style.marginXXS

              // Header
              RowLayout {
                Layout.fillWidth: true
                spacing: QsCommons.Style.marginS

                // Urgency dot
                Rectangle {
                  width: 6
                  height: 6
                  radius: 3
                  visible: model.urgency !== 1
                  color: model.urgency === 2
                    ? QsCommons.Color.mError
                    : QsCommons.Color.mOnSurfaceVariant
                }

                QsComponents.CText {
                  text: model.appName ?? "Unknown"
                  pointSize: QsCommons.Style.fontSizeXS
                  color: QsCommons.Color.mOnSurfaceVariant
                }

                QsComponents.CText {
                  text: QsCommons.Time.formatRelativeTime(model.timestamp)
                  pointSize: QsCommons.Style.fontSizeXS
                  color: QsCommons.Color.mOnSurfaceVariant
                }

                Item { Layout.fillWidth: true }
              }

              // Summary
              QsComponents.CText {
                id: summaryText
                text: model.summary ?? ""
                pointSize: QsCommons.Style.fontSizeM
                font.weight: QsCommons.Style.fontWeightMedium
                color: QsCommons.Color.mOnSurface
                textFormat: Text.PlainText  // Security: prevent HTML injection
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: isExpanded ? 999 : 2
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
              }

              // Body
              QsComponents.CText {
                id: bodyText
                text: model.body ?? ""
                pointSize: QsCommons.Style.fontSizeS
                color: QsCommons.Color.mOnSurfaceVariant
                textFormat: Text.PlainText  // Security: prevent HTML injection
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: isExpanded ? 999 : 3
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
              }

              // Expand hint
              RowLayout {
                Layout.fillWidth: true
                visible: !isExpanded && (summaryText.truncated || bodyText.truncated)
                spacing: QsCommons.Style.marginXS

                Item { Layout.fillWidth: true }

                QsComponents.CText {
                  text: "Click to expand"
                  pointSize: QsCommons.Style.fontSizeXS
                  color: QsCommons.Color.mPrimary
                  font.weight: QsCommons.Style.fontWeightMedium
                }

                QsComponents.CIcon {
                  icon: "chevron-down"
                  pointSize: QsCommons.Style.fontSizeS
                  color: QsCommons.Color.mPrimary
                }
              }
            }

            // Delete button
            QsComponents.CIconButton {
              icon: "trash"
              tooltipText: "Remove notification"
              baseSize: QsCommons.Style.baseWidgetSize * 0.7
              Layout.alignment: Qt.AlignTop
              onClicked: QsServices.NotificationService.removeFromHistory(notificationId)
            }
          }
        }
      }
    }
  }
}
