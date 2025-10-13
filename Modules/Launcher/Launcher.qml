// Application Launcher Panel for YAQS
// Fuzzy search powered by fuzzysort (https://github.com/farzher/fuzzysort)
// fuzzysort is MIT Licensed - Copyright (c) 2018 Stephen Kamenar

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../Commons"
import "../../Services"
import "../../Helpers/fuzzysort.js" as Fuzzysort
import "../../Widgets"

Panel {
    id: root

    // ===== Panel Configuration =====
    objectName: "launcherPanel"
    preferredWidth: Settings.data.launcher.width
    preferredHeight: Settings.data.launcher.height

    panelKeyboardFocus: true
    panelBackgroundColor: Qt.alpha(Settings.data.colors.mSurface, Settings.data.launcher.backgroundOpacity)

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
    property var applications: []
    property var filteredApps: []
    property bool sortByMostUsed: Settings.data.launcher.sortByMostUsed

    readonly property int entryHeight: Math.round(40 * scaling)

    // ===== Usage Tracking =====
    property string usageFilePath: Settings.cacheDir + "launcher_app_usage.json"

    // Debounced saver to avoid excessive IO
    Timer {
        id: saveUsageTimer
        interval: 750
        repeat: false
        onTriggered: usageFile.writeAdapter()
    }

    FileView {
        id: usageFile
        path: usageFilePath
        printErrors: false
        watchChanges: false

        onLoadFailed: function (error) {
            if (error.toString().includes("No such file") || error === 2) {
                writeAdapter()
            }
        }

        onAdapterUpdated: saveUsageTimer.start()

        JsonAdapter {
            id: usageAdapter
            property var counts: ({})
        }
    }

        // ===== Lifecycle =====
    onOpened: {
        searchText = "";
        selectedIndex = 0;
        loadApplications();
        updateFilteredApps();
    }

    onClosed: {
        searchText = "";
        selectedIndex = 0;
    }

    // ===== Application Loading =====
    Component.onCompleted: {
        loadApplications();
    }

    function loadApplications() {
        applications = [];

        if (typeof DesktopEntries === 'undefined') {
            Logger.error("Launcher", "DesktopEntries not available");
            return;
        }

        // DesktopEntries.applications is an ObjectModel<DesktopEntry>
        const allApps = DesktopEntries.applications.values || [];

        // Filter out apps that shouldn't be displayed
        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i];
            if (app && !app.noDisplay && app.name) {
                applications.push(app);
            }
        }

        Logger.log("Launcher", "Loaded", applications.length, "applications");
    }

    // ===== Usage Tracking Helpers =====
    function getAppKey(app) {
        if (app && app.id)
            return String(app.id);
        if (app && app.command && app.command.join)
            return app.command.join(" ");
        return String(app && app.name ? app.name : "unknown");
    }

    function getUsageCount(app) {
        const key = getAppKey(app);
        const counts = usageAdapter && usageAdapter.counts ? usageAdapter.counts : null;
        if (!counts)
            return 0;
        const value = counts[key];
        return typeof value === 'number' && isFinite(value) ? value : 0;
    }

    function recordUsage(app) {
        if (!sortByMostUsed) return; // Only track if most-used sorting is enabled
        
        const key = getAppKey(app);
        if (!usageAdapter.counts)
            usageAdapter.counts = ({});
        const current = getUsageCount(app);
        usageAdapter.counts[key] = current + 1;
        // Trigger save via debounced timer
        saveUsageTimer.restart();
        Logger.log("Launcher", "Recorded usage for", app.name, "- count:", current + 1);
    }

    function toggleSortMode() {
        sortByMostUsed = !sortByMostUsed;
        Settings.data.launcher.sortByMostUsed = sortByMostUsed;
        updateFilteredApps();
        Logger.log("Launcher", "Sort mode changed to:", sortByMostUsed ? "most-used" : "alphabetical");
    }

    function isFavorite(app) {
        const favoriteApps = Settings.data.launcher.favoriteApps || [];
        return favoriteApps.includes(getAppKey(app));
    }

    function toggleFavorite(app) {
        const key = getAppKey(app);
        let favorites = (Settings.data.launcher.favoriteApps || []).slice(); // Copy array
        const index = favorites.indexOf(key);
        
        if (index >= 0) {
            // Remove from favorites
            favorites.splice(index, 1);
            Logger.log("Launcher", "Removed from favorites:", app.name);
        } else {
            // Add to favorites
            favorites.push(key);
            Logger.log("Launcher", "Added to favorites:", app.name);
        }
        
        Settings.data.launcher.favoriteApps = favorites;
        updateFilteredApps(); // Re-sort with new favorite status
    }

    // ===== Filtering =====
    // Fuzzy search using fuzzysort (MIT License)
    function updateFilteredApps() {
        const query = searchText.trim();
        const favoriteApps = Settings.data.launcher.favoriteApps || [];

        if (!query) {
            // Show all apps, sorted based on user preference
            if (sortByMostUsed) {
                filteredApps = applications.slice().sort((a, b) => {
                    // Favorites first
                    const aFav = favoriteApps.includes(getAppKey(a));
                    const bFav = favoriteApps.includes(getAppKey(b));
                    if (aFav !== bFav)
                        return aFav ? -1 : 1;
                    
                    // Then by usage count
                    const usageA = getUsageCount(a);
                    const usageB = getUsageCount(b);
                    if (usageB !== usageA)
                        return usageB - usageA; // Most used first
                    
                    // Finally alphabetically
                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
                });
            } else {
                filteredApps = applications.slice().sort((a, b) => {
                    // Favorites first even in alphabetical mode
                    const aFav = favoriteApps.includes(getAppKey(a));
                    const bFav = favoriteApps.includes(getAppKey(b));
                    if (aFav !== bFav)
                        return aFav ? -1 : 1;
                    
                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
                });
            }
        } else {
            try {
                // Search across multiple fields
                const results = Fuzzysort.go(query, applications, {
                    keys: ['name', 'genericName', 'keywords', 'comment'],
                    limit: Settings.data.launcher.maxResults,
                    threshold: -10000
                });

                filteredApps = results.length > 0 ? results.map(result => result.obj) : [];
            } catch (e) {
                Logger.error("Launcher", "Fuzzysort failed:", e);
                filteredApps = simpleSearch(query);
            }
        }

        selectedIndex = 0;
    }

    // Fallback simple search if fuzzysort fails
    function simpleSearch(query) {
        const lowerQuery = String(query || '').toLowerCase();

        return applications.filter(app => {
            const name = String(app.name || '').toLowerCase();
            const genericName = String(app.genericName || '').toLowerCase();
            const keywords = String(app.keywords || '').toLowerCase();
            const comment = String(app.comment || '').toLowerCase();

            return name.includes(lowerQuery) ||
                   genericName.includes(lowerQuery) ||
                   keywords.includes(lowerQuery) ||
                   comment.includes(lowerQuery);
        }).sort((a, b) => {
            const aName = String(a.name || '').toLowerCase();
            const bName = String(b.name || '').toLowerCase();
            return aName.localeCompare(bName);
        });
    }

    onSearchTextChanged: {
        updateFilteredApps();
    }

    // ===== Launch Application =====
    function launchApp(app) {
        if (!app) return;

        try {
            Logger.log("Launcher", "Launching:", app.name);
            
            // Record usage for most-used sorting
            recordUsage(app);

            if (Settings.data.launcher.useApp2Unit && app.id) {
                // Use app2unit for systemd unit launching
                Logger.log("Launcher", "Using app2unit for:", app.id);
                if (app.runInTerminal) {
                    Quickshell.execDetached(["app2unit", "--", app.id + ".desktop"]);
                } else {
                    Quickshell.execDetached(["app2unit", "--"].concat(app.command));
                }
            } else {
                // Fallback logic when app2unit is not used
                if (app.runInTerminal) {
                    // Handle terminal apps manually
                    Logger.log("Launcher", "Executing terminal app manually:", app.name);
                    const terminal = Settings.data.launcher.terminalCommand.split(" ");
                    const command = terminal.concat(app.command);
                    Quickshell.execDetached({
                        command: command,
                        workingDirectory: app.workingDirectory
                    });
                } else if (app.execute) {
                    // Default execution for GUI apps
                    app.execute();
                } else {
                    Logger.warn("Launcher", "Could not launch:", app.name, "- No valid launch method");
                }
            }
            
            root.close();
        } catch (e) {
            Logger.error("Launcher", "Failed to launch", app.name, ":", e);
        }
    }

    // ===== Navigation =====
    function selectNext() {
        if (filteredApps.length > 0) {
            selectedIndex = Math.min(selectedIndex + 1, filteredApps.length - 1);
            ensureVisible(selectedIndex);
        }
    }

    function selectPrevious() {
        if (filteredApps.length > 0) {
            selectedIndex = Math.max(selectedIndex - 1, 0);
            ensureVisible(selectedIndex);
        }
    }

    function ensureVisible(index) {
        // Scroll to make selected item visible
        const itemY = index * entryHeight;
        const viewportTop = appList.contentY;
        const viewportBottom = viewportTop + appList.height;

        if (itemY < viewportTop) {
            appList.contentY = itemY;
        } else if (itemY + entryHeight > viewportBottom) {
            appList.contentY = itemY + entryHeight - appList.height;
        }
    }

    function activateSelected() {
        if (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            launchApp(filteredApps[selectedIndex]);
        }
    }

    // ===== UI =====
    panelContent: Rectangle {
        id: ui
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(Settings.data.ui.spacingL * scaling)
            spacing: Math.round(Settings.data.ui.spacingM * scaling)

            // ===== Header =====
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(Settings.data.ui.spacingM * scaling)

                Text {
                    text: "Applications"
                    font.family: Settings.data.ui.fontFamily
                    font.pixelSize: Math.round((Settings.data.ui.fontSizeXlarge + 4) * scaling)
                    font.weight: Font.Bold
                    color: Settings.data.colors.mOnSurface
                    Layout.fillWidth: true
                }

                // Sort mode toggle button
                Rectangle {
                    Layout.preferredWidth: Math.round(50 * scaling)
                    Layout.preferredHeight: Math.round(30 * scaling)
                    radius: Settings.data.ui.radiusM
                    color: sortToggleMouseArea.containsMouse 
                        ? Settings.data.colors.mPrimaryContainer 
                        : Settings.data.colors.mSurfaceVariant

                    Behavior on color {
                        ColorAnimation { duration: Settings.data.ui.durationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: sortByMostUsed ? "" : ""
                        font.pixelSize: Math.round(16 * scaling)
                    }

                    MouseArea {
                        id: sortToggleMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleSortMode()
                    }

                    // Tooltip
                    Text {
                        visible: sortToggleMouseArea.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: Math.round(4 * scaling)
                        text: sortByMostUsed ? "Most Used" : "Alphabetical"
                        font.family: Settings.data.ui.fontFamily
                        font.pixelSize: Math.round(Settings.data.ui.fontSizeSmall * scaling)
                        color: Settings.data.colors.mOnSurfaceVariant
                        z: 1000
                    }
                }
            }

            // ===== Search Input =====
            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(40 * scaling)
                color: Settings.data.colors.mSurfaceVariant
                radius: Settings.data.ui.radiusM
                border.color: searchInput.activeFocus
                    ? Settings.data.colors.mPrimary
                    : Settings.data.colors.mOutlineVariant
                border.width: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(Settings.data.ui.spacingM * scaling)
                    anchors.rightMargin: Math.round(Settings.data.ui.spacingM * scaling)
                    spacing: Math.round(Settings.data.ui.spacingS * scaling)

                    Text {
                        text: ""  // Search icon
                        font.family: Settings.data.ui.fontFamily
                        font.pixelSize: Math.round(Settings.data.ui.iconSize * scaling)
                        color: Settings.data.colors.mOnSurfaceVariant
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.family: Settings.data.ui.fontFamily
                        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
                        color: Settings.data.colors.mOnSurface
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true

                        text: searchText
                        onTextChanged: searchText = text

                        // Keyboard navigation
                        Keys.onDownPressed: selectNext()
                        Keys.onUpPressed: selectPrevious()
                        Keys.onReturnPressed: activateSelected()
                        Keys.onEnterPressed: activateSelected()
                        Keys.onEscapePressed: root.close()

                        // Auto-focus when component is ready
                        Component.onCompleted: {
                            forceActiveFocus();
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            text: "Search applications..."
                            font: searchInput.font
                            color: Settings.data.colors.mOnSurfaceVariant
                            opacity: Settings.data.ui.opacityMedium
                            visible: !searchInput.text
                        }
                    }

                    // Clear button
                    MouseArea {
                        Layout.preferredWidth: Math.round(Settings.data.ui.iconSize * scaling)
                        Layout.preferredHeight: Math.round(Settings.data.ui.iconSize * scaling)
                        visible: searchText.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchText = "";
                            searchInput.forceActiveFocus();
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""  // Close icon
                            font.family: Settings.data.ui.fontFamily
                            font.pixelSize: Math.round(Settings.data.ui.iconSize * scaling)
                            color: Settings.data.colors.mOnSurfaceVariant
                        }
                    }
                }
            }

            // ===== Application List =====
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Math.round(Settings.data.ui.spacingXs * scaling)

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: filteredApps
                    spacing: Math.round(Settings.data.ui.spacingXs * scaling)
                    currentIndex: selectedIndex

                    delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: root.entryHeight
                    color: index === selectedIndex
                        ? Settings.data.colors.mPrimaryContainer
                        : (appMouseArea.containsMouse ? Settings.data.colors.mSurfaceContainerHigh : "transparent")
                    radius: Settings.data.ui.radiusS

                    Behavior on color {
                        ColorAnimation { duration: Settings.data.ui.durationFast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(Settings.data.ui.spacingM * scaling)
                        anchors.rightMargin: Math.round(Settings.data.ui.spacingM * scaling)
                        spacing: Math.round(Settings.data.ui.spacingM * scaling)

                        // App Icon with fallback
                        Item {
                            Layout.preferredWidth: Math.round(32 * scaling)
                            Layout.preferredHeight: Math.round(32 * scaling)

                            Image {
                                id: appIcon
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
                                text: ""  // Generic app icon placeholder
                                font.family: Settings.data.ui.fontFamily
                                font.pixelSize: Math.round(24 * scaling)
                                color: index === selectedIndex
                                    ? Settings.data.colors.mOnPrimaryContainer
                                    : Settings.data.colors.mPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                visible: !appIcon.visible
                            }
                        }

                        // Text content
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Math.round(Settings.data.ui.spacingXs * scaling)

                                Text {
                                    text: modelData.name
                                    font.family: Settings.data.ui.fontFamily
                                    font.pixelSize: Math.round((Settings.data.ui.fontSizeLarge + 2) * scaling)
                                    font.weight: Font.Medium
                                    color: index === selectedIndex
                                        ? Settings.data.colors.mOnPrimaryContainer
                                        : Settings.data.colors.mOnSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Favorite indicator
                                Text {
                                    text: "⭐"
                                    font.pixelSize: Math.round(10 * scaling)
                                    visible: isFavorite(modelData)
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            Text {
                                text: modelData.comment || modelData.genericName || ""
                                font.family: Settings.data.ui.fontFamily
                                font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
                                color: index === selectedIndex
                                    ? Settings.data.colors.mOnPrimaryContainer
                                    : Settings.data.colors.mOnSurfaceVariant
                                opacity: Settings.data.ui.opacityHeavy
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text.length > 0
                            }
                        }
                    }

                    MouseArea {
                        id: appMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        
                        onClicked: (mouse) => {
                            selectedIndex = index;
                            if (mouse.button === Qt.LeftButton) {
                                launchApp(modelData);
                            } else if (mouse.button === Qt.RightButton) {
                                toggleFavorite(modelData);
                            }
                        }
                        
                        onEntered: selectedIndex = index
                    }
                }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: filteredApps.length === 0
                        text: searchText ? "No applications found" : "Loading applications..."
                        font.family: Settings.data.ui.fontFamily
                        font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
                        color: Settings.data.colors.mOnSurfaceVariant
                        opacity: Settings.data.ui.opacityMedium
                    }
                }

                // Scrollbar
                ScrollBar {
                    id: scrollBar
                    Layout.preferredWidth: Math.round(8 * scaling)
                    Layout.fillHeight: true
                    orientation: Qt.Vertical
                    policy: ScrollBar.AsNeeded
                    size: appList.height / appList.contentHeight
                    position: appList.contentY / appList.contentHeight

                    onPositionChanged: {
                        if (pressed) {
                            appList.contentY = position * appList.contentHeight;
                        }
                    }

                    contentItem: Rectangle {
                        implicitWidth: Math.round(6 * scaling)
                        radius: Math.round(3 * scaling)
                        color: scrollBar.pressed
                            ? Settings.data.colors.mPrimary
                            : (scrollBar.hovered
                                ? Settings.data.colors.mOnSurfaceVariant
                                : Qt.alpha(Settings.data.colors.mOnSurfaceVariant, 0.5))
                        opacity: scrollBar.size < 1.0 ? 1.0 : 0.0

                        Behavior on color {
                            ColorAnimation { duration: Settings.data.ui.durationFast }
                        }
                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }
    }
}
