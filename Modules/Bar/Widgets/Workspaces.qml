import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Commons
import qs.Services

Item {
    id: root

    // ===== Properties from Bar =====
    property var screen: null      // ShellScreen object
    property real scaling: 1.0     // DPI scaling

    // ===== Local state =====
    property ListModel localWorkspaces: ListModel {}  // Filtered for this monitor
    property bool effectsActive: false
    property real masterProgress: 0.0
    property color effectColor: Color.mPrimary
    property int lastFocusedWorkspaceId: -1  // Track last focused workspace to prevent unnecessary animations
    property bool hideUnoccupied: true  // Hide empty workspaces

    // Wheel scroll state
    property int wheelAccumulatedDelta: 0
    property bool wheelCooldown: false

    // ===== Sizing =====
    readonly property int pillSize: Math.round(12 * scaling)  // Compact pill size
    readonly property int pillSpacing: Math.round(Style.spacingXs * scaling)

    implicitWidth: computeWidth()
    implicitHeight: Math.round(Settings.data.bar.height * scaling)

    // ===== Computed dimensions =====
    function getPillWidth(ws) {
        const base = pillSize;
        return ws.isFocused ? (base * 2.2) : base;  // 2.2x wider when focused
    }

    function computeWidth() {
        let total = 0;
        for (var i = 0; i < localWorkspaces.count; i++) {
            total += getPillWidth(localWorkspaces.get(i));
        }
        total += Math.max(localWorkspaces.count - 1, 0) * pillSpacing;
        return Math.round(total);
    }

    // ===== Initialisation =====
    Component.onCompleted: {
        refreshWorkspaces();
    }

    onScreenChanged: refreshWorkspaces()
    onHideUnoccupiedChanged: refreshWorkspaces()

    // ===== Watch for workspace changes =====
    Connections {
        target: CompositorService
        function onWorkspaceChanged() {
            refreshWorkspaces();
            updateWorkspaceFocus();
        }
    }

    // ===== Per-monitor workspace filtering =====
    function refreshWorkspaces() {
        localWorkspaces.clear();

        if (!screen)
            return;

        // Collect all active workspaces for this monitor
        const activeWorkspaces = [];
        for (var i = 0; i < CompositorService.workspaces.count; i++) {
            const ws = CompositorService.workspaces.get(i);
            if (ws.output.toLowerCase() === screen.name.toLowerCase()) {
                if (hideUnoccupied && !ws.isOccupied && !ws.isFocused) {
                    continue;
                }
                activeWorkspaces.push(ws);
            }
        }

        // Limit to 10 slots maximum
        const maxSlots = 10;
        if (activeWorkspaces.length <= maxSlots) {
            // Show all workspaces
            for (var j = 0; j < activeWorkspaces.length; j++) {
                localWorkspaces.append(activeWorkspaces[j]);
            }
        } else {
            // More than 10 workspaces: show first 9 + focused (if beyond 9) or highest
            for (var k = 0; k < maxSlots - 1; k++) {
                localWorkspaces.append(activeWorkspaces[k]);
            }

            // Slot 10: show focused workspace if it's beyond slot 9, otherwise show highest
            var focusedWorkspace = null;
            for (var m = maxSlots - 1; m < activeWorkspaces.length; m++) {
                if (activeWorkspaces[m].isFocused) {
                    focusedWorkspace = activeWorkspaces[m];
                    break;
                }
            }

            if (focusedWorkspace) {
                localWorkspaces.append(focusedWorkspace);
            } else {
                localWorkspaces.append(activeWorkspaces[activeWorkspaces.length - 1]);
            }
        }
    }

    // ===== Focus change animation =====
    function updateWorkspaceFocus() {
        for (var i = 0; i < localWorkspaces.count; i++) {
            const ws = localWorkspaces.get(i);
            if (ws.isFocused) {
                // Only trigger burst effect if workspace actually changed
                if (lastFocusedWorkspaceId !== ws.idx) {
                    lastFocusedWorkspaceId = ws.idx;
                    triggerBurstEffect();
                }
                break;
            }
        }
    }

    function triggerBurstEffect() {
        effectColor = Color.mPrimary;
        burstAnimation.restart();
    }

    SequentialAnimation {
        id: burstAnimation
        PropertyAction {
            target: root
            property: "effectsActive"
            value: true
        }
        NumberAnimation {
            target: root
            property: "masterProgress"
            from: 0.0
            to: 1.0
            duration: Style.durationSlow * 2
            easing.type: Easing.OutQuint
        }
        PropertyAction {
            target: root
            property: "effectsActive"
            value: false
        }
        PropertyAction {
            target: root
            property: "masterProgress"
            value: 0.0
        }
    }

    // ===== Workspace switching helpers =====
    function getFocusedLocalIndex() {
        for (var i = 0; i < localWorkspaces.count; i++) {
            if (localWorkspaces.get(i).isFocused) {
                return i;
            }
        }
        return -1;
    }

    function switchByOffset(offset) {
        if (localWorkspaces.count === 0)
            return;
        var current = getFocusedLocalIndex();
        if (current < 0)
            current = 0;

        var next = (current + offset) % localWorkspaces.count;
        if (next < 0)
            next = localWorkspaces.count - 1;

        const ws = localWorkspaces.get(next);
        if (ws && ws.idx !== undefined) {
            CompositorService.switchToWorkspace(ws.idx);
        }
    }

    // ===== Wheel scroll support =====
    Timer {
        id: wheelDebounce
        interval: 150
        repeat: false
        onTriggered: {
            root.wheelCooldown = false;
            root.wheelAccumulatedDelta = 0;
        }
    }

    WheelHandler {
        target: root
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            if (root.wheelCooldown)
                return;
            var delta = event.angleDelta.y;
            root.wheelAccumulatedDelta += delta;

            if (Math.abs(root.wheelAccumulatedDelta) >= 120) {
                // One notch
                var direction = root.wheelAccumulatedDelta > 0 ? -1 : 1;
                root.switchByOffset(direction);
                root.wheelCooldown = true;
                wheelDebounce.restart();
                root.wheelAccumulatedDelta = 0;
                event.accepted = true;
            }
        }
    }

    // ===== UI: Pill-style workspace indicators =====
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: pillSpacing

        Repeater {
            model: localWorkspaces

            Item {
                id: pillContainer
                width: root.getPillWidth(model)
                height: root.pillSize

                Rectangle {
                    id: pill
                    anchors.fill: parent
                    radius: width * 0.5  // Fully rounded

                    color: {
                        if (model.isUrgent)
                            return Color.mError;
                        if (model.isFocused)
                            return Color.mPrimary;
                        if (model.isOccupied)
                            return Color.mOnSurface;
                        return Qt.alpha(Color.mOutlineVariant, 0.3);
                    }

                    scale: model.isFocused ? 1.0 : 0.9

                    // Show workspace number on focused pill
                    Text {
                        visible: model.isFocused
                        anchors.centerIn: parent
                        text: model.idx
                        font.family: Style.fontFamily
                        font.pixelSize: Math.round(pillContainer.height * 0.6)
                        font.weight: Font.DemiBold
                        color: Color.mSurface  // Contrasting colour
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            CompositorService.switchToWorkspace(model.idx);
                        }
                    }

                    // Smooth animations
                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationNormal
                            easing.type: Easing.OutBack
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Style.durationFast
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Style.durationNormal
                            easing.type: Easing.OutBack
                        }
                    }
                }

                // Burst effect (animated ring on focus)
                Rectangle {
                    id: burst
                    anchors.centerIn: pillContainer
                    width: pillContainer.width + 12 * root.masterProgress
                    height: pillContainer.height + 12 * root.masterProgress
                    radius: width * 0.5
                    color: "transparent"
                    border.color: root.effectColor
                    border.width: Math.max(1, Math.round((2 + 4 * (1.0 - root.masterProgress)) * scaling))
                    opacity: root.effectsActive && model.isFocused ? (1.0 - root.masterProgress) * 0.7 : 0
                    visible: root.effectsActive && model.isFocused
                }

                // Smooth container resize
                Behavior on width {
                    NumberAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.OutBack
                    }
                }
            }
        }
    }
}
