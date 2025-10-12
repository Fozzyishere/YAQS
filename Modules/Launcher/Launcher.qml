import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../Commons"
import "../../Services"
import "../../Widgets"
import "../../Helpers/uFuzzy.js" as UFuzzy

Panel {
    id: root

    // ===== Panel Configuration =====
    objectName: "launcherPanel"
    preferredWidth: 350
    preferredHeight: 450

    panelKeyboardFocus: true
    panelBackgroundColor: Qt.alpha(Settings.data.colors.mSurface, 0.95)

    // ===== Positioning =====
    // Position near AppLauncher button using button-relative positioning
    panelAnchorLeft: true
    panelAnchorTop: true

    // ===== State =====
    property string searchText: ""
    property int selectedIndex: 0
    property var applications: []
    property var appNames: []  // Array of app names for uFuzzy
    property var filteredApps: []
    property var ufuzzy: null  // uFuzzy instance

    readonly property int entryHeight: Math.round(40 * scaling)

    // ===== Lifecycle =====
    onOpened: {
        searchText = "";
        selectedIndex = 0;
        loadApplications();
        updateFilteredApps();
        searchInput.forceActiveFocus();
    }

    onClosed: {
        searchText = "";
        selectedIndex = 0;
    }

    // ===== Application Loading =====
    Component.onCompleted: {
        // Initialize uFuzzy with optimized settings for app launcher
        ufuzzy = UFuzzy.uFuzzy({
            intraMode: 1,      // Single-error tolerance (typos)
            intraIns: 1,       // Allow 1 insertion per term
            intraSub: 1,       // Allow 1 substitution per term
            intraTrn: 1,       // Allow 1 transposition per term
            intraDel: 1,       // Allow 1 deletion per term
        });

        loadApplications();
    }

    function loadApplications() {
        applications = [];
        appNames = [];

        // Get applications from DesktopEntries
        if (typeof DesktopEntries === 'undefined') {
            Logger.warn("Launcher", "DesktopEntries not available");
            return;
        }

        const allApps = DesktopEntries.applications.values || [];

        // Filter out apps that shouldn't be displayed
        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i];
            if (app && !app.noDisplay && app.name) {
                applications.push(app);
                // Build searchable string: name + generic name + keywords + comment
                const searchStr = [
                    app.name,
                    app.genericName || '',
                    app.keywords || '',
                    app.comment || ''
                ].filter(s => s).join(' ');
                appNames.push(searchStr);
            }
        }

        Logger.log("Launcher", "Loaded", applications.length, "applications");
    }

    // ===== Filtering =====
    function updateFilteredApps() {
        if (!searchText || searchText.trim() === "") {
            // Show all apps, sorted alphabetically
            filteredApps = applications.slice().sort((a, b) =>
                a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            );
        } else if (ufuzzy && appNames.length > 0) {
            const [idxs, info, order] = ufuzzy.search(appNames, searchText);

            if (idxs && idxs.length > 0) {
                filteredApps = [];
                const sortedIdxs = order || idxs;
                for (let i = 0; i < Math.min(sortedIdxs.length, 50); i++) {
                    const idx = order ? idxs[sortedIdxs[i]] : sortedIdxs[i];
                    if (idx < applications.length) {
                        filteredApps.push(applications[idx]);
                    }
                }
            } else {
                filteredApps = [];
            }
        } else {
            // Fallback to simple case-insensitive search
            const query = searchText.toLowerCase();
            filteredApps = applications.filter(app => {
                if (app.name && app.name.toLowerCase().includes(query)) return true;
                if (app.genericName && app.genericName.toLowerCase().includes(query)) return true;
                if (app.keywords && app.keywords.toLowerCase().includes(query)) return true;
                if (app.comment && app.comment.toLowerCase().includes(query)) return true;
                return false;
            }).sort((a, b) =>
                a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            );
        }

        selectedIndex = 0;
    }

    onSearchTextChanged: updateFilteredApps()

    // ===== Launch Application =====
    function launchApp(app) {
        if (!app) return;

        Logger.log("Launcher", "Launching:", app.name);

        try {
            // Use the built-in execute() method
            app.execute();
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
                    font.pixelSize: Math.round(Settings.data.ui.fontSizeLarge * scaling)
                    font.weight: Font.DemiBold
                    color: Settings.data.colors.mOnSurface
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: filteredApps.length + " apps"
                    font.family: Settings.data.ui.fontFamily
                    font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
                    color: Settings.data.colors.mOnSurfaceVariant
                    opacity: Settings.data.ui.opacityHeavy
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
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: filteredApps
                spacing: Math.round(Settings.data.ui.spacingXs * scaling)
                currentIndex: selectedIndex

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

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

                        // Icon (placeholder for now)
                        Text {
                            text: ""  // App icon placeholder
                            font.family: Settings.data.ui.fontFamily
                            font.pixelSize: Math.round(24 * scaling)
                            color: index === selectedIndex
                                ? Settings.data.colors.mOnPrimaryContainer
                                : Settings.data.colors.mPrimary
                            Layout.preferredWidth: Math.round(32 * scaling)
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Text content
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: modelData.name
                                font.family: Settings.data.ui.fontFamily
                                font.pixelSize: Math.round(Settings.data.ui.fontSize * scaling)
                                font.weight: Font.Medium
                                color: index === selectedIndex
                                    ? Settings.data.colors.mOnPrimaryContainer
                                    : Settings.data.colors.mOnSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.comment || modelData.genericName || ""
                                font.family: Settings.data.ui.fontFamily
                                font.pixelSize: Math.round(Settings.data.ui.fontSizeSmall * scaling)
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
                        onClicked: {
                            selectedIndex = index;
                            launchApp(modelData);
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
        }
    }
}
