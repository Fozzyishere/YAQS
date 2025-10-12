import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../Commons"
import "../../Services"
import "../../Widgets"

Panel {
    id: root

    // ===== Panel Configuration =====
    objectName: "sessionMenuPanel"
    preferredWidth: 280
    preferredHeight: 380
    panelAnchorRight: true
    panelAnchorTop: true
    panelKeyboardFocus: true

    // ===== Timer Properties =====
    property int timerDuration: 9000  // 9 seconds
    property string pendingAction: ""
    property bool timerActive: false
    property int timeRemaining: 0

    // ===== Navigation =====
    property int selectedIndex: 0
    readonly property var powerOptions: [
        {
            "action": "lock",
            "icon": "",  // lock
            "title": "Lock",
            "subtitle": "Lock your screen",
            "isDestructive": false
        },
        {
            "action": "suspend",
            "icon": "",  // sleep/suspend
            "title": "Suspend",
            "subtitle": "Suspend to RAM",
            "isDestructive": false
        },
        {
            "action": "logout",
            "icon": "",  // logout
            "title": "Logout",
            "subtitle": "End your session",
            "isDestructive": true
        },
        {
            "action": "reboot",
            "icon": "",  // reboot
            "title": "Reboot",
            "subtitle": "Restart your computer",
            "isDestructive": true
        },
        {
            "action": "shutdown",
            "icon": "",  // shutdown
            "title": "Shutdown",
            "subtitle": "Power off your computer",
            "isDestructive": true
        }
    ]

    // ===== Lifecycle =====
    onOpened: {
        selectedIndex = 0;
    }

    onClosed: {
        cancelTimer();
        selectedIndex = 0;
    }

    // ===== Timer Management =====
    function startTimer(action) {
        if (timerActive && pendingAction === action) {
            // Second click - execute immediately
            executeAction(action);
            return;
        }

        pendingAction = action;
        timeRemaining = timerDuration;
        timerActive = true;
        countdownTimer.start();
    }

    function cancelTimer() {
        timerActive = false;
        pendingAction = "";
        timeRemaining = 0;
        countdownTimer.stop();
    }

    function executeAction(action) {
        countdownTimer.stop();

        Logger.log("SessionMenu", "Executing action:", action);

        try {
            switch (action) {
            case "lock":
                // Use external locker (hyprlock, swaylock, etc.)
                Quickshell.execDetached(["hyprlock"]);
                break;
            case "suspend":
                Quickshell.execDetached(["systemctl", "suspend"]);
                break;
            case "logout":
                if (typeof HyprlandService !== 'undefined') {
                    HyprlandService.logout();
                } else {
                    Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                }
                break;
            case "reboot":
                Quickshell.execDetached(["systemctl", "reboot"]);
                break;
            case "shutdown":
                Quickshell.execDetached(["systemctl", "poweroff"]);
                break;
            }
        } catch (e) {
            Logger.error("SessionMenu", "Failed to execute action:", action, e);
        }

        cancelTimer();
        root.close();
    }

    // ===== Navigation =====
    function selectNext() {
        if (powerOptions.length > 0) {
            selectedIndex = Math.min(selectedIndex + 1, powerOptions.length - 1);
        }
    }

    function selectPrevious() {
        if (powerOptions.length > 0) {
            selectedIndex = Math.max(selectedIndex - 1, 0);
        }
    }

    function selectFirst() {
        selectedIndex = 0;
    }

    function selectLast() {
        if (powerOptions.length > 0) {
            selectedIndex = powerOptions.length - 1;
        } else {
            selectedIndex = 0;
        }
    }

    function activate() {
        if (powerOptions.length > 0 && selectedIndex >= 0 && selectedIndex < powerOptions.length) {
            const option = powerOptions[selectedIndex];
            startTimer(option.action);
        }
    }

    // ===== Countdown Timer =====
    Timer {
        id: countdownTimer
        interval: 100
        repeat: true
        onTriggered: {
            timeRemaining -= interval;
            if (timeRemaining <= 0) {
                executeAction(pendingAction);
            }
        }
    }

    // ===== UI =====
    panelContent: Rectangle {
        id: ui
        color: "transparent"

        // ===== Keyboard Shortcuts =====
        Shortcut {
            sequence: "Up"
            onActivated: selectPrevious()
            enabled: root.opened
        }

        Shortcut {
            sequence: "Down"
            onActivated: selectNext()
            enabled: root.opened
        }

        Shortcut {
            sequence: "Home"
            onActivated: selectFirst()
            enabled: root.opened
        }

        Shortcut {
            sequence: "End"
            onActivated: selectLast()
            enabled: root.opened
        }

        Shortcut {
            sequence: "Return"
            onActivated: activate()
            enabled: root.opened
        }

        Shortcut {
            sequence: "Enter"
            onActivated: activate()
            enabled: root.opened
        }

        Shortcut {
            sequence: "Escape"
            onActivated: {
                if (timerActive) {
                    cancelTimer();
                } else {
                    root.close();
                }
            }
            context: Qt.WidgetShortcut
            enabled: root.opened
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: Math.round(Settings.data.ui.spacingL * scaling)
            anchors.leftMargin: Math.round(Settings.data.ui.spacingL * scaling)
            anchors.rightMargin: Math.round(Settings.data.ui.spacingL * scaling)
            anchors.bottomMargin: Math.round(Settings.data.ui.spacingM * scaling)
            spacing: Math.round(Settings.data.ui.spacingS * scaling)

            // ===== Header =====
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(32 * scaling)

                Text {
                    text: timerActive
                        ? pendingAction.charAt(0).toUpperCase() + pendingAction.slice(1) +
                          " in " + Math.ceil(timeRemaining / 1000) + "s"
                        : "Session Menu"
                    font.family: Settings.data.ui.fontFamily
                    font.pixelSize: Math.round(Settings.data.ui.fontSizeLarge * scaling)
                    font.weight: Font.DemiBold
                    color: timerActive ? Settings.data.colors.mPrimary : Settings.data.colors.mOnSurface
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                }

                // Close/Cancel button
                MouseArea {
                    Layout.preferredWidth: Math.round(32 * scaling)
                    Layout.preferredHeight: Math.round(32 * scaling)
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (timerActive) {
                            cancelTimer();
                        } else {
                            root.close();
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Settings.data.ui.radiusFull
                        color: parent.containsMouse
                            ? (timerActive ? Qt.alpha(Settings.data.colors.mError, 0.1) : Settings.data.colors.mSurfaceContainerHigh)
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: timerActive ? "" : ""  // stop or close icon
                            font.family: Settings.data.ui.fontFamily
                            font.pixelSize: Math.round(Settings.data.ui.iconSize * scaling)
                            color: timerActive ? Settings.data.colors.mError : Settings.data.colors.mOnSurface
                        }
                    }
                }
            }

            // ===== Divider =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Settings.data.colors.mOutlineVariant
            }

            // ===== Power Options =====
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Math.round(Settings.data.ui.spacingM * scaling)

                Repeater {
                    model: powerOptions
                    delegate: PowerButton {
                        Layout.fillWidth: true
                        icon: modelData.icon
                        title: modelData.title
                        subtitle: modelData.subtitle
                        isDestructive: modelData.isDestructive || false
                        isSelected: index === selectedIndex
                        pending: timerActive && pendingAction === modelData.action
                        onClicked: {
                            selectedIndex = index;
                            startTimer(modelData.action);
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    // ===== Power Button Component =====
    component PowerButton: Rectangle {
        id: buttonRoot

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool pending: false
        property bool isDestructive: false
        property bool isSelected: false

        signal clicked

        height: Math.round(64 * scaling)
        radius: Settings.data.ui.radiusS * scaling
        color: {
            if (pending) {
                return Qt.alpha(Settings.data.colors.mPrimary, 0.08);
            }
            if (isSelected || mouseArea.containsMouse) {
                return Settings.data.colors.mSurfaceContainerHigh;
            }
            return "transparent";
        }

        border.width: pending ? Math.max(2, 2 * scaling) : 0
        border.color: pending ? Settings.data.colors.mPrimary : Settings.data.colors.mOutline

        Behavior on color {
            ColorAnimation {
                duration: Settings.data.ui.durationFast
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(Settings.data.ui.spacingL * scaling)
            anchors.rightMargin: Math.round(Settings.data.ui.spacingL * scaling)
            spacing: Math.round(Settings.data.ui.spacingM * scaling)

            // Icon
            Text {
                text: buttonRoot.icon
                font.family: Settings.data.ui.fontFamily
                font.pixelSize: Math.round(24 * scaling)
                color: {
                    if (buttonRoot.pending) return Settings.data.colors.mPrimary;
                    if (buttonRoot.isDestructive && !buttonRoot.isSelected && !mouseArea.containsMouse) {
                        return Settings.data.colors.mError;
                    }
                    return Settings.data.colors.mOnSurface;
                }
                Layout.preferredWidth: Math.round(32 * scaling)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Settings.data.ui.durationFast }
                }
            }

            // Text content
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: buttonRoot.title
                    font.family: Settings.data.ui.fontFamily
                    font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
                    font.weight: Font.Medium
                    color: {
                        if (buttonRoot.pending) return Settings.data.colors.mPrimary;
                        if (buttonRoot.isDestructive && !buttonRoot.isSelected && !mouseArea.containsMouse) {
                            return Settings.data.colors.mError;
                        }
                        return Settings.data.colors.mOnSurface;
                    }

                    Behavior on color {
                        ColorAnimation { duration: Settings.data.ui.durationFast }
                    }
                }

                Text {
                    text: buttonRoot.pending ? "Click again to execute" : buttonRoot.subtitle
                    font.family: Settings.data.ui.fontFamily
                    font.pixelSize: Math.round(Settings.data.ui.fontSizeSmall * scaling)
                    color: {
                        if (buttonRoot.pending) return Settings.data.colors.mPrimary;
                        if (buttonRoot.isDestructive && !buttonRoot.isSelected && !mouseArea.containsMouse) {
                            return Settings.data.colors.mError;
                        }
                        return Settings.data.colors.mOnSurfaceVariant;
                    }
                    opacity: Settings.data.ui.opacityHeavy
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }

            // Pending indicator
            Rectangle {
                Layout.preferredWidth: Math.round(24 * scaling)
                Layout.preferredHeight: Math.round(24 * scaling)
                radius: width * 0.5
                color: Settings.data.colors.mPrimary
                visible: buttonRoot.pending

                Text {
                    anchors.centerIn: parent
                    text: Math.ceil(timeRemaining / 1000)
                    font.family: Settings.data.ui.fontFamily
                    font.pixelSize: Math.round(Settings.data.ui.fontSizeSmall * scaling)
                    font.weight: Font.DemiBold
                    color: Settings.data.colors.mSurface
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.clicked()
            onEntered: selectedIndex = index
        }
    }
}
