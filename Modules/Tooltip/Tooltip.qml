import QtQuick
import Quickshell

import "../../Commons"

PopupWindow {
    id: root

    property string text: ""
    property int delay: 500
    property int margin: 8
    property int padding: 8
    property int maxWidth: 300

    // Internal
    property var targetItem: null
    property real anchorX: 0
    property real anchorY: 0
    property bool pendingShow: false

    visible: false
    color: "transparent"

    anchor.item: targetItem
    anchor.rect.x: anchorX
    anchor.rect.y: anchorY

    // Show timer
    Timer {
        id: showTimer
        interval: root.delay
        repeat: false
        onTriggered: {
            root.positionAndShow();
        }
    }

    // Show animation
    ParallelAnimation {
        id: showAnimation

        PropertyAnimation {
            target: container
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: Settings.data.ui.durationFast
            easing.type: Easing.OutCubic
        }

        PropertyAnimation {
            target: container
            property: "scale"
            from: 0.9
            to: 1.0
            duration: Settings.data.ui.durationFast
            easing.type: Easing.OutCubic
        }
    }

    // Hide animation
    ParallelAnimation {
        id: hideAnimation

        PropertyAnimation {
            target: container
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: Settings.data.ui.durationFast
            easing.type: Easing.InCubic
        }

        PropertyAnimation {
            target: container
            property: "scale"
            from: 1.0
            to: 0.9
            duration: Settings.data.ui.durationFast
            easing.type: Easing.InCubic
        }

        onFinished: {
            root.visible = false;
            root.text = "";
        }
    }

    function show(target, tipText, showDelay) {
        if (!target || !tipText || tipText === "") {
            return;
        }

        showTimer.stop();
        hideAnimation.stop();

        if (visible && targetItem !== target) {
            hideImmediately();
        }

        targetItem = target;
        text = tipText;
        pendingShow = true;
        delay = showDelay || 500;

        showTimer.start();
    }

    function positionAndShow() {
        if (!targetItem || !targetItem.parent || !pendingShow) {
            return;
        }

        const screenWidth = Screen.width;
        const screenHeight = Screen.height;

        // Calculate tooltip dimensions
        const tipWidth = Math.min(tooltipText.implicitWidth + (padding * 2), maxWidth);
        root.width = tipWidth;
        const tipHeight = tooltipText.implicitHeight + (padding * 2);
        root.height = tipHeight;

        // Get target position
        const targetGlobal = targetItem.mapToGlobal(0, 0);
        const targetWidth = targetItem.width;
        const targetHeight = targetItem.height;

        // Position below target by default
        let newAnchorX = (targetWidth - tipWidth) / 2;
        let newAnchorY = targetHeight + margin;

        // Check if fits below
        if (targetGlobal.y + targetHeight + margin + tipHeight > screenHeight) {
            // Show above instead
            newAnchorY = -tipHeight - margin;
        }

        // Adjust horizontal to stay on screen
        const globalX = targetGlobal.x + newAnchorX;
        if (globalX < 0) {
            newAnchorX = -targetGlobal.x + margin;
        } else if (globalX + tipWidth > screenWidth) {
            newAnchorX = screenWidth - targetGlobal.x - tipWidth - margin;
        }

        anchorX = newAnchorX;
        anchorY = newAnchorY;
        pendingShow = false;

        visible = true;
        container.opacity = 0.0;
        container.scale = 0.9;
        showAnimation.start();
    }

    function hide() {
        showTimer.stop();
        pendingShow = false;

        if (visible) {
            hideAnimation.start();
        }
    }

    function hideImmediately() {
        showTimer.stop();
        showAnimation.stop();
        hideAnimation.stop();
        pendingShow = false;
        visible = false;
        text = "";
        container.opacity = 1.0;
        container.scale = 1.0;
    }

    function updateText(newText) {
        if (visible && targetItem) {
            text = newText;
        }
    }

    // Content container
    Item {
        id: container
        anchors.fill: parent
        opacity: 1.0
        scale: 1.0
        transformOrigin: Item.Center

        Rectangle {
            anchors.fill: parent
            color: Settings.data.colors.mSurfaceContainer
            border.color: Settings.data.colors.mOutline
            border.width: 1
            radius: Settings.data.ui.radiusM

            Text {
                id: tooltipText
                anchors.centerIn: parent
                anchors.margins: root.padding
                text: root.text
                font.family: Settings.data.ui.fontFamily
                font.pixelSize: Settings.data.ui.fontSize
                color: Settings.data.colors.mOnSurface
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                width: root.maxWidth - (root.padding * 2)
            }
        }
    }
}
