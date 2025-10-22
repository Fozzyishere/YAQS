import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"
import "../Services"

Loader {
    id: root

    // ===== Required Properties =====
    property ShellScreen screen
    property real scaling: 1.0

    // ===== Panel Content =====
    property Component panelContent: null

    // ===== Size Configuration =====
    property real preferredWidth: 700
    property real preferredHeight: 900
    property real preferredWidthRatio: 0.0   // If > 0, uses ratio of screen width
    property real preferredHeightRatio: 0.0  // If > 0, uses ratio of screen height

    // ===== Appearance =====
    property color panelBackgroundColor: Color.mSurface
    property bool draggable: false

    // ===== Positioning Anchors =====
    property bool panelAnchorHorizontalCenter: false
    property bool panelAnchorVerticalCenter: false
    property bool panelAnchorTop: false
    property bool panelAnchorBottom: false
    property bool panelAnchorLeft: false
    property bool panelAnchorRight: false

    // ===== Button-relative Positioning =====
    property bool useButtonPosition: false
    property point buttonPosition: Qt.point(0, 0)
    property int buttonWidth: 0
    property int buttonHeight: 0

    // ===== Behavior =====
    property bool panelKeyboardFocus: false
    property bool backgroundClickEnabled: true
    property bool isMasked: false

    // ===== Animation State =====
    readonly property real originalScale: 0.7
    readonly property real originalOpacity: 0.0
    property real scaleValue: originalScale
    property real opacityValue: originalOpacity
    property real dimmingOpacity: 0

    property alias isClosing: hideTimer.running

    // ===== Signals =====
    signal opened
    signal closed

    // ===== Loader Configuration =====
    active: false
    asynchronous: true

    // ===== Registration =====
    Component.onCompleted: {
        PanelService.registerPanel(root);
    }

    // ===== Background Click Control =====

    function disableBackgroundClick() {
        backgroundClickEnabled = false;
    }

    function enableBackgroundClick() {
        // Delay to prevent immediate close after drag release
        enableBackgroundClickTimer.restart();
    }

    Timer {
        id: enableBackgroundClickTimer
        interval: 100
        repeat: false
        onTriggered: backgroundClickEnabled = true
    }

    // ===== Public API =====

    /**
     * Toggle panel open/closed
     * @param buttonItem - Optional button widget for positioning
     */
    function toggle(buttonItem) {
        if (!active || isClosing) {
            open(buttonItem);
        } else {
            close();
        }
    }

    /**
     * Open the panel
     * @param buttonItem - Optional button widget for positioning
     */
    function open(buttonItem) {
        // Capture button position if provided
        if (buttonItem !== undefined && buttonItem !== null) {
            useButtonPosition = true;

            const itemPos = buttonItem.mapToItem(null, 0, 0);
            buttonPosition = Qt.point(itemPos.x, itemPos.y);
            buttonWidth = buttonItem.width;
            buttonHeight = buttonItem.height;
        } else {
            useButtonPosition = false;
        }

        // If currently closing, stop the timer
        if (isClosing) {
            hideTimer.stop();
            scaleValue = 1.0;
            opacityValue = 1.0;
        }

        PanelService.willOpenPanel(root);

        backgroundClickEnabled = true;
        active = true;
        root.opened();
    }

    /**
     * Close the panel
     */
    function close() {
        dimmingOpacity = 0;
        scaleValue = originalScale;
        opacityValue = originalOpacity;
        hideTimer.start();
        PanelService.willClosePanel(root);
    }

    /**
     * Called when close animation completes
     */
    function closeCompleted() {
        root.closed();
        active = false;
        useButtonPosition = false;
        backgroundClickEnabled = true;
        PanelService.closedPanel(root);
    }

    // ===== Close Timer =====
    Timer {
        id: hideTimer
        interval: Style.durationSlow
        repeat: false
        onTriggered: closeCompleted()
    }

    // ===== Panel Window Component =====
    sourceComponent: Component {
        PanelWindow {
            id: panelWindow

            // ===== Scaling =====
            property real scaling: Scaling.getScreenScale(screen)

            // ===== Bar Position Awareness =====
            readonly property string barPosition: Settings.data.bar.position
            readonly property bool isVertical: barPosition === "left" || barPosition === "right"
            readonly property bool barIsVisible: (screen !== null) &&
                (Settings.data.bar.monitors.includes(screen.name) ||
                 (Settings.data.bar.monitors.length === 0))

            // ===== Lifecycle =====
            Component.onCompleted: {
                root.scaling = scaling;
                Logger.log("Panel", "Opened", root.objectName);
                dimmingOpacity = Style.opacityHeavy;
            }

            // ===== Scaling Updates =====
            onScalingChanged: {
                root.scaling = scaling;
            }

            Connections {
                target: Scaling
                function onScaleChanged(screenName, scale) {
                    if ((screen !== null) && (screenName === screen.name)) {
                        root.scaling = scaling = scale;
                    }
                }
            }

            // ===== Screen Changes =====
            Connections {
                target: panelWindow
                function onScreenChanged() {
                    root.screen = screen;
                    root.scaling = scaling = Scaling.getScreenScale(screen);

                    // Refresh panel content for new screen
                    panelContentLoader.active = false;
                    panelContentLoader.active = true;
                }
            }

            // ===== Window Configuration =====
            visible: true
            color: Settings.data.general && Settings.data.general.dimDesktop && !root.isMasked
                ? Qt.alpha(Color.mShadow, dimmingOpacity)
                : Color.transparent

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "yaqs-panel"
            WlrLayershell.keyboardFocus: root.panelKeyboardFocus
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

            mask: root.isMasked ? maskRegion : null

            Region {
                id: maskRegion
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.durationSlow
                }
            }

            // ===== Full Screen Anchors =====
            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true

            // ===== Keyboard Shortcut =====
            Shortcut {
                sequences: ["Escape"]
                enabled: root.active && !root.isClosing
                onActivated: root.close()
                context: Qt.WindowShortcut
            }

            // ===== Background Click to Close =====
            MouseArea {
                anchors.fill: parent
                enabled: root.backgroundClickEnabled
                onClicked: root.close()
            }

            // ===== Panel Content Background =====
            Rectangle {
                id: panelBackground
                color: panelBackgroundColor
                radius: Style.radiusL * scaling
                border.color: Color.mOutline
                border.width: Math.max(1, 2 * scaling)

                // ===== Dragging Support =====
                property bool draggable: root.draggable
                property bool isDragged: false
                property real manualX: 0
                property real manualY: 0

                // ===== Size Calculation =====
                width: {
                    let w;
                    if (preferredWidthRatio > 0) {
                        w = Math.round(Math.max(screen?.width * preferredWidthRatio, preferredWidth) * scaling);
                    } else {
                        w = preferredWidth * scaling;
                    }
                    // Clamp to screen bounds
                    return Math.min(w, (screen?.width || 1920) - Style.spacingL * 2);
                }

                height: {
                    let h;
                    if (preferredHeightRatio > 0) {
                        h = Math.round(Math.max(screen?.height * preferredHeightRatio, preferredHeight) * scaling);
                    } else {
                        h = preferredHeight * scaling;
                    }
                    // Clamp to screen bounds
                    const barHeight = Settings.data.bar.height * scaling;
                    return Math.min(h, (screen?.height || 1080) - barHeight - Style.spacingL * 2);
                }

                // ===== Animation =====
                scale: root.scaleValue
                opacity: root.isMasked ? 0 : root.opacityValue
                x: isDragged ? manualX : calculatedX
                y: isDragged ? manualY : calculatedY

                // ===== Margin Calculations (Bar-aware) =====
                property real marginTop: {
                    if (!barIsVisible) return Style.spacingS * scaling;
                    if (panelAnchorVerticalCenter) return 0;

                    if (barPosition === "top") {
                        const barMargin = (Settings.data.bar.height + Settings.data.bar.marginTop) * scaling;
                        return barMargin + Style.spacingS * scaling;
                    }
                    return Style.spacingS * scaling;
                }

                property real marginBottom: {
                    if (!barIsVisible || panelAnchorVerticalCenter) return 0;

                    if (barPosition === "bottom") {
                        const barMargin = (Settings.data.bar.height + Settings.data.bar.marginBottom) * scaling;
                        return barMargin + Style.spacingS * scaling;
                    }
                    return Style.spacingS * scaling;
                }

                property real marginLeft: {
                    if (!barIsVisible || panelAnchorHorizontalCenter) return 0;

                    if (barPosition === "left") {
                        const barMargin = (Settings.data.bar.height + Settings.data.bar.marginSide) * scaling;
                        return barMargin + Style.spacingS * scaling;
                    }
                    return Style.spacingS * scaling;
                }

                property real marginRight: {
                    if (!barIsVisible || panelAnchorHorizontalCenter) return 0;

                    if (barPosition === "right") {
                        const barMargin = (Settings.data.bar.height + Settings.data.bar.marginSide) * scaling;
                        return barMargin + Style.spacingS * scaling;
                    }
                    return Style.spacingS * scaling;
                }

                // ===== Position Calculation =====
                property int calculatedX: {
                    // Priority to fixed anchoring
                    if (panelAnchorHorizontalCenter) {
                        return Math.round((panelWindow.width - panelBackground.width) / 2);
                    } else if (panelAnchorLeft) {
                        return marginLeft;
                    } else if (panelAnchorRight) {
                        return Math.round(panelWindow.width - panelBackground.width - marginRight);
                    }

                    // Button-relative positioning
                    if (root.useButtonPosition && !isVertical) {
                        const targetX = buttonPosition.x + (buttonWidth / 2) - (panelBackground.width / 2);
                        const maxX = panelWindow.width - panelBackground.width - marginRight;
                        const minX = marginLeft;
                        return Math.round(Math.max(minX, Math.min(targetX, maxX)));
                    }

                    // Default to center
                    return Math.round((panelWindow.width - panelBackground.width) / 2);
                }

                property int calculatedY: {
                    // Priority to fixed anchoring
                    if (panelAnchorVerticalCenter) {
                        return Math.round((panelWindow.height - panelBackground.height) / 2);
                    } else if (panelAnchorTop) {
                        return marginTop;
                    } else if (panelAnchorBottom) {
                        return Math.round(panelWindow.height - panelBackground.height - marginBottom);
                    }

                    // Button-relative positioning for vertical bars
                    if (root.useButtonPosition && isVertical) {
                        const targetY = buttonPosition.y + (buttonHeight / 2) - (panelBackground.height / 2);
                        const maxY = panelWindow.height - panelBackground.height - marginBottom;
                        const minY = marginTop;
                        return Math.round(Math.max(minY, Math.min(targetY, maxY)));
                    }

                    // Default positioning based on bar
                    if (barPosition === "bottom") {
                        return Math.round(panelWindow.height - panelBackground.height - marginBottom);
                    } else {
                        return marginTop;
                    }
                }

                // ===== Animation Start =====
                Component.onCompleted: {
                    root.scaleValue = 1.0;
                    root.opacityValue = 1.0;
                }

                // ===== Reset Drag on Close =====
                Connections {
                    target: root
                    function onClosed() {
                        panelBackground.isDragged = false;
                    }
                }

                // ===== Prevent Click-through =====
                MouseArea {
                    anchors.fill: parent
                }

                // ===== Animation Behaviors =====
                Behavior on scale {
                    NumberAnimation {
                        duration: Style.durationSlow
                        easing.type: Easing.OutExpo
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Style.durationNormal
                        easing.type: Easing.OutQuad
                    }
                }

                // ===== Panel Content =====
                Loader {
                    id: panelContentLoader
                    anchors.fill: parent
                    sourceComponent: root.panelContent
                }

                // ===== Drag Handler =====
                DragHandler {
                    id: dragHandler
                    target: null
                    enabled: panelBackground.draggable
                    property real dragStartX: 0
                    property real dragStartY: 0

                    onActiveChanged: {
                        if (active) {
                            panelBackground.manualX = panelBackground.x;
                            panelBackground.manualY = panelBackground.y;
                            dragStartX = panelBackground.x;
                            dragStartY = panelBackground.y;
                            panelBackground.isDragged = true;
                            if (root.enableBackgroundClick) {
                                root.disableBackgroundClick();
                            }
                        } else {
                            if (root.enableBackgroundClick) {
                                root.enableBackgroundClick();
                            }
                        }
                    }

                    onTranslationChanged: {
                        const nx = dragStartX + translation.x;
                        const ny = dragStartY + translation.y;

                        const baseGap = Style.spacingS * scaling;
                        const insetLeft = baseGap + panelBackground.marginLeft;
                        const insetRight = baseGap + panelBackground.marginRight;
                        const insetTop = baseGap + panelBackground.marginTop;
                        const insetBottom = baseGap + panelBackground.marginBottom;

                        const maxX = panelWindow.width - panelBackground.width - insetRight;
                        const minX = insetLeft;
                        const maxY = panelWindow.height - panelBackground.height - insetBottom;
                        const minY = insetTop;

                        panelBackground.manualX = Math.round(Math.max(minX, Math.min(nx, maxX)));
                        panelBackground.manualY = Math.round(Math.max(minY, Math.min(ny, maxY)));
                    }
                }

                // ===== Drag Indicator =====
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 0
                    color: Color.transparent
                    border.color: Color.mPrimary
                    border.width: Math.max(2, 3 * scaling)
                    radius: parent.radius
                    visible: panelBackground.isDragged && dragHandler.active
                    opacity: 0.8
                    z: 3000

                    // Glow effect
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 0
                        color: Color.transparent
                        border.color: Color.mPrimary
                        border.width: Math.max(1, 1 * scaling)
                        radius: parent.radius
                        opacity: 0.3
                    }
                }
            }
        }
    }
}
