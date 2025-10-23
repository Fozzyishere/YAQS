import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Services

Item {
    id: root

    // ===== Properties from Bar =====
    property var screen: null
    property real scaling: 1.0

    // ===== Layout alignment =====
    Layout.alignment: Qt.AlignVCenter

    // ===== Computed properties =====
    readonly property string windowTitle: CompositorService.getFocusedWindowTitle()
    readonly property bool hasActiveWindow: windowTitle !== ""
    readonly property real widgetWidth: screen ? Math.max(200, screen.width * 0.06) : 200

    // ===== Sizing =====
    width: widgetWidth * scaling
    implicitHeight: Math.round(Settings.data.bar.height * scaling)
    Layout.maximumWidth: widgetWidth * scaling

    // ===== Auto-hide when no window =====
    opacity: hasActiveWindow ? 1.0 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Style.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    // ===== Hidden text for measuring full title width =====
    Text {
        id: fullTitleMetrics
        visible: false
        text: windowTitle
        font.family: Style.fontFamily
        font.pixelSize: Math.round(Style.fontSize * scaling)
    }

    // ===== Title container with clipping =====
    Item {
        id: titleContainer
        anchors.fill: parent
        clip: true

        property real textWidth: fullTitleMetrics.contentWidth
        property real containerWidth: width
        property bool needsScrolling: textWidth > containerWidth
        property bool isScrolling: false
        property bool isResetting: false

        // ===== Scrolling content with duplicate text =====
        Item {
            id: scrollContainer
            height: parent.height
            width: childrenRect.width

            property real scrollX: 0
            x: scrollX

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 50 * scaling

                // Primary text
                Text {
                    id: titleText
                    text: windowTitle
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(Style.fontSize * scaling)
                    color: Color.mOutlineVariant
                    verticalAlignment: Text.AlignVCenter
                }

                // Duplicate text for seamless loop
                Text {
                    text: windowTitle
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round(Style.fontSize * scaling)
                    color: Color.mOutlineVariant
                    verticalAlignment: Text.AlignVCenter
                    visible: titleContainer.needsScrolling
                }
            }

            // ===== Scroll animation (on hover) =====
            NumberAnimation on scrollX {
                running: mouseArea.containsMouse && titleContainer.needsScrolling
                from: 0
                to: -(titleContainer.textWidth + 50 * scaling)
                duration: Math.max(4000, windowTitle.length * 100)
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }

            // ===== Reset animation (on exit) =====
            NumberAnimation on scrollX {
                running: titleContainer.isResetting
                to: 0
                duration: 300
                easing.type: Easing.OutQuad
                onFinished: {
                    titleContainer.isResetting = false
                }
            }
        }

        // ===== State management function =====
        function updateScrollingState() {
            if (mouseArea.containsMouse && needsScrolling) {
                isScrolling = true
                isResetting = false
            } else if (!mouseArea.containsMouse && needsScrolling && scrollContainer.scrollX !== 0) {
                isScrolling = false
                isResetting = true
            } else {
                isScrolling = false
                isResetting = false
            }
        }

        // React to hover changes
        Connections {
            target: mouseArea
            function onContainsMouseChanged() {
                titleContainer.updateScrollingState()
            }
        }

        Component.onCompleted: updateScrollingState()
    }

    // ===== Mouse area for hover detection =====
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
