import QtQuick
import QtQuick.Layouts

import "../Commons"

/**
 * Collapsible - Expandable section with header and content
 *
 * An expandable/collapsible section with animated expansion, chevron rotation,
 * and color transitions. Based on Noctalia's NCollapsible.
 *
 * Features:
 * - Animated expand/collapse
 * - Rotating chevron indicator
 * - Header color changes when expanded
 * - Smooth height and opacity transitions
 * - Default property for easy content addition
 * - Per-screen scaling support
 *
 * Usage:
 *   Collapsible {
 *       label: "Advanced Settings"
 *       description: "Configure advanced options"
 *       defaultExpanded: false
 *
 *       Toggle { label: "Option 1" }
 *       Toggle { label: "Option 2" }
 *       Slider { from: 0; to: 100 }
 *   }
 */
ColumnLayout {
    id: root

    // Public properties
    property string label: ""
    property string description: ""
    property bool expanded: false
    property bool defaultExpanded: false
    property real contentSpacing: Style.spacingM * scaling
    property real scaling: 1.0

    // Signals
    signal toggled(bool expanded)

    // Layout
    Layout.fillWidth: true
    spacing: 0

    // Default property to accept children
    default property alias content: contentLayout.children

    // Header with clickable area
    Rectangle {
        id: headerContainer
        Layout.fillWidth: true
        Layout.preferredHeight: headerContent.implicitHeight + (Style.spacingL * scaling * 2)

        // Material 3 style background
        color: root.expanded ? Color.mSecondary : Color.mSurfaceVariant
        radius: Style.radiusL * scaling

        // Border
        border.color: root.expanded ? Color.mOnSecondary : Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)

        // Color transitions
        Behavior on color {
            ColorAnimation {
                duration: Style.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Style.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: {
                root.expanded = !root.expanded
                root.toggled(root.expanded)
            }

            // Hover effect overlay
            Rectangle {
                anchors.fill: parent
                color: headerArea.containsMouse ? Color.mOnSurface : Color.transparent
                opacity: headerArea.containsMouse ? 0.08 : 0
                radius: headerContainer.radius

                Behavior on opacity {
                    NumberAnimation {
                        duration: Style.durationFast
                    }
                }
            }
        }

        RowLayout {
            id: headerContent
            anchors.fill: parent
            anchors.margins: Style.spacingL * scaling
            spacing: Style.spacingM * scaling

            // Chevron icon with rotation
            Text {
                id: chevronIcon
                text: "›"  // Right chevron
                font.family: Style.fontFamily
                font.pixelSize: Math.round(Style.fontSize * 1.5 * scaling)
                font.weight: Font.Bold
                color: root.expanded ? Color.mOnSecondary : Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter

                rotation: root.expanded ? 90 : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Style.durationNormal
                    }
                }
            }

            // Header text content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Style.spacingXxs * scaling

                Text {
                    text: root.label
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(Style.fontSize * 1.1 * scaling)
                    font.weight: Font.DemiBold
                    color: root.expanded ? Color.mOnSecondary : Color.mOnSurface
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap

                    Behavior on color {
                        ColorAnimation {
                            duration: Style.durationNormal
                        }
                    }
                }

                Text {
                    text: root.description
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(Style.fontSize * 0.85 * scaling)
                    font.weight: Font.Normal
                    color: root.expanded ? Color.mOnSecondary : Color.mOnSurfaceVariant
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: root.description !== ""
                    opacity: 0.87

                    Behavior on color {
                        ColorAnimation {
                            duration: Style.durationNormal
                        }
                    }
                }
            }
        }
    }

    // Collapsible content container
    Rectangle {
        id: contentContainer
        Layout.fillWidth: true
        Layout.topMargin: Style.spacingS * scaling

        visible: root.expanded
        color: Color.mSurface
        radius: Style.radiusL * scaling
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)

        // Dynamic height based on content
        Layout.preferredHeight: visible ? contentLayout.implicitHeight + (Style.spacingL * scaling * 2) : 0

        // Smooth height animation
        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: Style.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        // Content layout
        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: Style.spacingL * scaling
            spacing: root.contentSpacing

            // Clip content during animation
            clip: true
        }

        // Fade in animation
        opacity: root.expanded ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: Style.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    // Initialize expanded state
    Component.onCompleted: {
        root.expanded = root.defaultExpanded
    }
}
