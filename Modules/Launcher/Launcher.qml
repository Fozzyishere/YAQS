// Application Launcher Panel for YAQS
// Plugin-based architecture for extensible launcher functionality

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Panel {
    id: root

    // ===== Panel Configuration =====
    objectName: "launcherPanel"
    preferredWidth: Settings.data.launcher.width
    preferredHeight: Settings.data.launcher.height

    panelKeyboardFocus: true
    panelBackgroundColor: Qt.alpha(Color.mSurface, Settings.data.launcher.backgroundOpacity)

    // ===== Positioning =====
    // Position based on user preference
    readonly property string launcherPosition: Settings.data.launcher.position
    panelAnchorHorizontalCenter: launcherPosition === "center" || launcherPosition.endsWith("_center")
    panelAnchorVerticalCenter: launcherPosition === "center"
    panelAnchorLeft: launcherPosition !== "center" && launcherPosition.endsWith("_left")
    panelAnchorRight: launcherPosition !== "center" && launcherPosition.endsWith("_right")
    panelAnchorBottom: launcherPosition.startsWith("bottom_")
    panelAnchorTop: launcherPosition.startsWith("top_") || launcherPosition === "center"

    // ===== State =====
    property string searchText: ""
    property int selectedIndex: 0
    property var results: []
    property var plugins: []
    property var activePlugin: null

    readonly property int entryHeight: Math.round(40 * scaling)

    // ===== Plugin System =====
    function registerPlugin(plugin) {
        plugins.push(plugin)
        plugin.launcher = root
        if (plugin.init)
            plugin.init()
    }

    function updateResults() {
        results = []
        activePlugin = null

        // Check for command mode
        if (searchText.startsWith(">")) {
            // Find plugin that handles this command
            for (let i = 0; i < plugins.length; i++) {
                const plugin = plugins[i]
                if (plugin.handleCommand && plugin.handleCommand(searchText)) {
                    activePlugin = plugin
                    results = plugin.getResults(searchText)
                    break
                }
            }

            // Show available commands if just ">"
            if (searchText === ">" && !activePlugin) {
                for (let i = 0; i < plugins.length; i++) {
                    const plugin = plugins[i]
                    if (plugin.commands) {
                        results = results.concat(plugin.commands())
                    }
                }
            }
        } else {
            // Regular search - let plugins contribute results
            for (let i = 0; i < plugins.length; i++) {
                const plugin = plugins[i]
                if (plugin.handleSearch) {
                    const pluginResults = plugin.getResults(searchText)
                    results = results.concat(pluginResults)
                }
            }
        }

        selectedIndex = 0
    }

    onSearchTextChanged: updateResults()

    // ===== Lifecycle =====
    onOpened: {
        searchText = ""
        selectedIndex = 0

        // Notify plugins
        for (let i = 0; i < plugins.length; i++) {
            const plugin = plugins[i]
            if (plugin.onOpened)
                plugin.onOpened()
        }

        updateResults()
        searchInput.forceActiveFocus()
    }

    onClosed: {
        searchText = ""
        selectedIndex = 0

        // Notify plugins
        for (let i = 0; i < plugins.length; i++) {
            const plugin = plugins[i]
            if (plugin.onClosed)
                plugin.onClosed()
        }
    }

    // ===== Plugin Loading =====
    Component.onCompleted: {
        // Load applications plugin
        const appsPlugin = Qt.createComponent("Plugins/ApplicationsPlugin.qml").createObject(root)
        if (appsPlugin) {
            registerPlugin(appsPlugin)
            Logger.log("Launcher", "Registered: ApplicationsPlugin")
        } else {
            Logger.error("Launcher", "Failed to load ApplicationsPlugin")
        }

        // Load calculator plugin
        const calcPlugin = Qt.createComponent("Plugins/CalculatorPlugin.qml").createObject(root)
        if (calcPlugin) {
            registerPlugin(calcPlugin)
            Logger.log("Launcher", "Registered: CalculatorPlugin")
        } else {
            Logger.error("Launcher", "Failed to load CalculatorPlugin")
        }

        // Load clipboard plugin (if enabled in settings)
        if (Settings.data.launcher.enableClipboardHistory) {
            const clipPlugin = Qt.createComponent("Plugins/ClipboardPlugin.qml").createObject(root)
            if (clipPlugin) {
                registerPlugin(clipPlugin)
                Logger.log("Launcher", "Registered: ClipboardPlugin")
            } else {
                Logger.error("Launcher", "Failed to load ClipboardPlugin")
            }
        }
    }


    // ===== Navigation =====
    function selectNext() {
        if (results.length > 0) {
            selectedIndex = Math.min(selectedIndex + 1, results.length - 1)
            ensureVisible(selectedIndex)
        }
    }

    function selectPrevious() {
        if (results.length > 0) {
            selectedIndex = Math.max(selectedIndex - 1, 0)
            ensureVisible(selectedIndex)
        }
    }

    function ensureVisible(index) {
        // Scroll to make selected item visible
        const itemY = index * entryHeight
        const viewportTop = scrollView.ScrollBar.vertical.position * appListContent.height
        const viewportBottom = viewportTop + scrollView.height

        if (itemY < viewportTop) {
            scrollView.ScrollBar.vertical.position = itemY / appListContent.height
        } else if (itemY + entryHeight > viewportBottom) {
            scrollView.ScrollBar.vertical.position = (itemY + entryHeight - scrollView.height) / appListContent.height
        }
    }

    function activateSelected() {
        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
            const result = results[selectedIndex]
            if (result && result.onActivate) {
                result.onActivate()
            }
        }
    }

    // ===== UI =====
    panelContent: Rectangle {
        id: ui
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(Style.spacingL * scaling)
            spacing: Math.round(Style.spacingM * scaling)

            // ===== Header =====
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(Style.spacingM * scaling)

                Text {
                    text: "Applications"
                    font.family: Style.fontFamily
                    font.pixelSize: Math.round((Style.fontSizeXlarge + 4) * scaling)
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }

                // Sort mode toggle button with tooltip
                Item {
                    Layout.preferredWidth: Math.round(40 * scaling)
                    Layout.preferredHeight: Math.round(40 * scaling)

                    IconButton {
                        id: sortToggleButton
                        anchors.centerIn: parent
                        icon: {
                            // Get sort mode from ApplicationsPlugin if available
                            for (let i = 0; i < plugins.length; i++) {
                                const plugin = plugins[i]
                                if (plugin.name === "Applications" && plugin.sortByMostUsed !== undefined) {
                                    return plugin.sortByMostUsed ? "" : ""
                                }
                            }
                            return ""
                        }
                        variant: "secondary"
                        sizePreset: "medium"
                        scaling: root.scaling
                        onClicked: {
                            // Call toggleSortMode on ApplicationsPlugin
                            for (let i = 0; i < plugins.length; i++) {
                                const plugin = plugins[i]
                                if (plugin.name === "Applications" && plugin.toggleSortMode) {
                                    plugin.toggleSortMode()
                                    break
                                }
                            }
                        }

                        property bool hovered: false
                    }

                    // Tooltip
                    Text {
                        visible: sortToggleButton.hovered
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: Math.round(4 * scaling)
                        text: {
                            for (let i = 0; i < plugins.length; i++) {
                                const plugin = plugins[i]
                                if (plugin.name === "Applications" && plugin.sortByMostUsed !== undefined) {
                                    return plugin.sortByMostUsed ? "Most Used" : "Alphabetical"
                                }
                            }
                            return "Sort"
                        }
                        font.family: Style.fontFamily
                        font.pixelSize: Math.round(Style.fontSizeSmall * scaling)
                        color: Color.mOnSurfaceVariant
                        z: 1000
                    }

                    MouseArea {
                        anchors.fill: sortToggleButton
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: sortToggleButton.hovered = true
                        onExited: sortToggleButton.hovered = false
                        onPressed: mouse => mouse.accepted = false
                    }
                }
            }

            // ===== Search Input =====
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.round((Style.fontSize + Style.spacingM * 2) * 1.5 * scaling)

                // Background frame
                Rectangle {
                    id: searchFrame
                    anchors.fill: parent
                    radius: Style.radiusM * scaling
                    color: Color.mSurface
                    border.color: searchInput.activeFocus ? Color.mSecondary : Color.mOutline
                    border.width: Math.max(1, Style.borderS * scaling)

                    Behavior on border.color {
                        ColorAnimation { duration: Style.durationFast }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(Style.spacingM * scaling)
                    anchors.rightMargin: Math.round(Style.spacingM * scaling)
                    spacing: Math.round(Style.spacingS * scaling)

                    // Search icon
                    Text {
                        text: ""
                        font.family: Style.fontFamily
                        font.pixelSize: Math.round(Style.iconSize * scaling)
                        color: Color.mOnSurfaceVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Search input field
                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: searchText
                        placeholderText: "Search applications..."
                        placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.6)

                        color: Color.mOnSurface
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter

                        background: null

                        font.family: Style.fontFamily
                        font.pixelSize: Math.round(Style.fontSize * scaling)
                        font.weight: Font.Normal

                        onTextChanged: searchText = text

                        Component.onCompleted: {
                            forceActiveFocus()

                            // Keyboard navigation
                            Keys.onDownPressed.connect(selectNext)
                            Keys.onUpPressed.connect(selectPrevious)
                            Keys.onReturnPressed.connect(activateSelected)
                            Keys.onEnterPressed.connect(activateSelected)
                            Keys.onEscapePressed.connect(root.close)
                        }
                    }

                    // Clear button (inside search bar)
                    IconButton {
                        visible: searchText.length > 0
                        opacity: searchText.length > 0 ? 1 : 0
                        icon: ""
                        variant: "text"
                        sizePreset: "small"
                        scaling: root.scaling
                        Layout.alignment: Qt.AlignVCenter

                        onClicked: {
                            searchText = ""
                            searchInput.forceActiveFocus()
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: Style.durationFast }
                        }
                    }
                }
            }

            // ===== Results List =====
            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                scaling: root.scaling
                verticalPolicy: ScrollBar.AsNeeded
                horizontalPolicy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: appListContent
                    width: scrollView.width
                    spacing: Math.round(Style.spacingXs * scaling)

                    Repeater {
                        model: results

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: root.entryHeight
                            color: index === selectedIndex
                                ? Color.mPrimaryContainer
                                : (listItemMouseArea.containsMouse ? Color.mSurfaceContainerHigh : "transparent")
                            radius: Math.round(Style.radiusS * scaling)

                            Behavior on color {
                                ColorAnimation { duration: Style.durationFast }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(Style.spacingM * scaling)
                                anchors.rightMargin: Math.round(Style.spacingM * scaling)
                                spacing: Math.round(Style.spacingM * scaling)

                                // Icon with fallback
                                Item {
                                    Layout.preferredWidth: Math.round(32 * scaling)
                                    Layout.preferredHeight: Math.round(32 * scaling)

                                    Image {
                                        id: resultIcon
                                        anchors.fill: parent
                                        source: modelData.icon ? `image://icon/${modelData.icon}` : ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        asynchronous: true
                                        visible: status === Image.Ready && modelData.icon
                                    }

                                    // Fallback icon when image fails to load
                                    Text {
                                        anchors.fill: parent
                                        text: ""
                                        font.family: Style.fontFamily
                                        font.pixelSize: Math.round(24 * scaling)
                                        color: index === selectedIndex
                                            ? Color.mOnPrimaryContainer
                                            : Color.mPrimary
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        visible: !resultIcon.visible
                                    }
                                }

                                // Text content
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(Style.spacingXs * scaling)

                                        Text {
                                            text: modelData.name || "Unknown"
                                            font.family: Style.fontFamily
                                            font.pixelSize: Math.round((Style.fontSizeLarge + 2) * scaling)
                                            font.weight: Font.Medium
                                            color: index === selectedIndex
                                                ? Color.mOnPrimaryContainer
                                                : Color.mOnSurface
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Favorite indicator
                                        Text {
                                            text: "⭐"
                                            font.pixelSize: Math.round(10 * scaling)
                                            visible: modelData.isFavorite === true
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    Text {
                                        text: modelData.description || ""
                                        font.family: Style.fontFamily
                                        font.pixelSize: Math.round(Style.fontSize * scaling)
                                        color: index === selectedIndex
                                            ? Color.mOnPrimaryContainer
                                            : Color.mOnSurfaceVariant
                                        opacity: Style.opacityHeavy
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                    }
                                }
                            }

                            MouseArea {
                                id: listItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onClicked: (mouse) => {
                                    selectedIndex = index
                                    if (mouse.button === Qt.LeftButton) {
                                        // Activate the result
                                        if (modelData.onActivate) {
                                            modelData.onActivate()
                                        }
                                    } else if (mouse.button === Qt.RightButton) {
                                        // Toggle favorite
                                        if (modelData.onToggleFavorite) {
                                            modelData.onToggleFavorite()
                                        }
                                    }
                                }

                                onEntered: selectedIndex = index
                            }
                        }
                    }

                    // Empty state
                    Text {
                        visible: results.length === 0
                        text: searchText ? "No results found" : "Loading..."
                        font.family: Style.fontFamily
                        font.pixelSize: Math.round(Style.fontSize * scaling)
                        color: Color.mOnSurfaceVariant
                        opacity: Style.opacityMedium
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Math.round(Style.spacingL * scaling)
                    }
                }
            }
        }
    }
}
