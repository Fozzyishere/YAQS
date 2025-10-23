import QtQuick
import QtQuick.Layouts

import qs.Commons

/**
 * Card - Container with elevation and optional title
 *
 * A Material Design 3 inspired card container for grouping related content.
 * Provides rounded corners, optional title, and configurable padding.
 *
 * Features:
 * - Optional title header
 * - Configurable content padding
 * - Rounded corners
 * - Border styling
 * - Per-screen scaling support
 * - Default property for easy content addition
 *
 * Usage:
 *   Card {
 *       title: "System Info"
 *       contentPadding: Style.spacingL
 *
 *       ColumnLayout {
 *           Label { text: "CPU: 45%" }
 *           Label { text: "Memory: 60%" }
 *       }
 *   }
 */
Rectangle {
    id: root

    // Public properties
    property string title: ""
    property real contentPadding: Style.spacingL * scaling
    property real scaling: 1.0

    // Default property for content
    default property alias content: contentContainer.data

    // Appearance
    color: Color.mSurfaceContainer
    radius: Style.radiusL * scaling
    border.color: Color.mOutline
    border.width: Math.max(1, Style.borderS * scaling)

    // Auto-size based on content
    implicitWidth: contentLayout.implicitWidth + contentPadding * 2
    implicitHeight: contentLayout.implicitHeight + contentPadding * 2

    // Main layout
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: Style.spacingM * scaling

        // Title header (if provided)
        Text {
            visible: root.title !== ""
            text: root.title
            font.family: Style.fontFamily
            font.pixelSize: Math.round(Style.fontSize * 1.2 * scaling)
            font.weight: Font.DemiBold
            color: Color.mOnSurface
            Layout.fillWidth: true
        }

        // Divider below title (if title exists)
        Divider {
            visible: root.title !== ""
            Layout.fillWidth: true
            thickness: Style.borderS
            color: Color.mOutline
            scaling: root.scaling
        }

        // Content container
        Item {
            id: contentContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
