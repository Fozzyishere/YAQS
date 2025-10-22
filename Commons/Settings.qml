pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Settings version - increment when schema changes
    readonly property int currentSettingsVersion: 3

    // Access pattern: Settings.data.bar.height, Settings.data.colors.mPrimary
    readonly property alias data: adapter
    property bool isLoaded: false
    property bool directoriesCreated: false
    property bool allowSave: false  // Prevent saves during initialization

    // Configuration paths
    property string shellName: "quickshell"
    property string configDir: Quickshell.env("HOME") + "/.config/" + shellName + "/"
    property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/" + shellName + "/"
    property string settingsFile: configDir + "settings.json"

    // Signal emitted when settings are loaded
    signal settingsLoaded

    Component.onCompleted: {
        // Ensure config directory exists
        Quickshell.execDetached(["mkdir", "-p", configDir])
        Quickshell.execDetached(["mkdir", "-p", cacheDir])
        directoriesCreated = true

        Logger.log("Settings", "Initializing settings system...")

        if (adapter.settingsVersion === undefined || adapter.settingsVersion < 1) {
            adapter.settingsVersion = 1
        }

        // Set adapter connection
        settingsFileView.adapter = adapter
    }

    // Auto-save with debounce to avoid excessive IO
    Timer {
        id: saveTimer
        interval: 1000
        repeat: false
        onTriggered: {
            settingsFileView.writeAdapter()
            Logger.log("Settings", "Settings saved to disk")
        }
    }

    FileView {
        id: settingsFileView
        path: directoriesCreated ? settingsFile : undefined
        printErrors: false
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: {
            if (allowSave) {
                saveTimer.start()
            }
        }

        onPathChanged: {
            if (path !== undefined) {
                reload()
            }
        }

        onLoaded: function() {
            if (!isLoaded) {
                Logger.log("Settings", "Settings loaded from: " + settingsFile)

                upgradeSettings()
                validateSettings()

                isLoaded = true
                allowSave = true  // Enable auto-save after initial load complete
                settingsLoaded()
            }
        }

        onLoadFailed: function(error) {
            if (error.toString().includes("No such file") || error === 2) {
                // File doesn't exist, create with defaults
                Logger.log("Settings", "No settings file found, creating with defaults")
                adapter.settingsVersion = currentSettingsVersion
                writeAdapter()
                allowSave = true  // Enable auto-save for new installs
            } else {
                Logger.error("Settings", "Failed to load settings:", error)
            }
        }
    }

    JsonAdapter {
        id: adapter

        property int settingsVersion: 1

        // ==================== Bar Configuration ====================
        property JsonObject bar: JsonObject {
            // Bar positioning
            property string position: "top"  // "top", "bottom", "left", "right"
            property int height: 22
            property int marginTop: 4
            property int marginSide: 4
            property int marginBottom: 4

            // Bar appearance
            property real backgroundOpacity: 1.0
            property bool floating: false
            property real floatingMarginVertical: 0.25
            property real floatingMarginHorizontal: 0.25
            property string density: "default"  // "compact", "default", "comfortable"
            property bool showCapsule: true

            // Monitor configuration (empty = all monitors)
            property list<string> monitors: []

            // Widget configuration for modular bar system
            property JsonObject widgets
            widgets: JsonObject {
                property list<var> left: [
                    { "id": "AppLauncher" },
                    { "id": "Clock" },
                    { "id": "WindowTitle" }
                ]
                property list<var> center: [
                    { "id": "Workspaces" }
                ]
                property list<var> right: [
                    { "id": "MediaMini" },
                    { "id": "WiFi" },
                    { "id": "Brightness" },
                    { "id": "Audio" },
                    { "id": "Battery" },
                    { "id": "PowerMenu" }
                ]
            }
        }

        // ==================== Scaling Configuration ====================
        property JsonObject scaling: JsonObject {
            // Per-screen DPI scale overrides
            // Example: { "DP-1": 1.5, "HDMI-1": 1.0 }
            property var screenScales: ({})
        }

        // ==================== Network Configuration ====================
        property JsonObject network: JsonObject {
            property bool wifiEnabled: true
            property int updateInterval: 30000  // WiFi state polling interval (ms)
        }

        // ==================== Audio Configuration ====================
        property JsonObject audio: JsonObject {
            property int volumeStep: 5
            property bool volumeOverdrive: false
        }

        // ==================== Brightness Configuration ====================
        property JsonObject brightness: JsonObject {
            property int pollInterval: 500  // Polling interval for light backend (ms)
            property int step: 5            // Brightness adjustment step size
        }

        // ==================== Launcher Configuration ====================
        property JsonObject launcher: JsonObject {
            // Launch behavior
            property bool useApp2Unit: false
            property string terminalCommand: "xterm -e"

            // Display and sorting
            property bool sortByMostUsed: true
            property list<string> favoriteApps: []
            property int maxResults: 50

            // Position and appearance
            property string position: "top_left"  // "top_left", "top_center", "top_right", "center", "bottom_left", "bottom_center", "bottom_right"
            property real backgroundOpacity: 0.95
            property int width: 350
            property int height: 450
        }

        // ==================== Session Menu Configuration ====================
        property JsonObject sessionMenu: JsonObject {
            property int confirmationDelay: 9000  // Countdown duration (ms)
            property bool enableConfirmation: true
            property int width: 280
            property int height: 380
        }
    }

    // ==================== Utility Functions ====================

    /**
     * Get bar widget settings for a specific section and index
     * @param section - "left", "center", or "right"
     * @param index - Widget index in that section
     * @return Widget configuration object or null
     */
    function getBarWidget(section, index) {
        if (!data.bar.widgets[section]) return null
        const widgets = data.bar.widgets[section]
        if (index < 0 || index >= widgets.length) return null
        return widgets[index]
    }

    /**
     * Update bar widget settings
     * @param section - "left", "center", or "right"
     * @param index - Widget index in that section
     * @param widgetData - New widget configuration
     */
    function setBarWidget(section, index, widgetData) {
        if (!data.bar.widgets[section]) return
        var widgets = data.bar.widgets[section]
        if (index < 0 || index >= widgets.length) return

        widgets[index] = widgetData
        // Trigger save via adapter update
        saveTimer.start()
    }

    /**
     * Add a widget to a section
     * @param section - "left", "center", or "right"
     * @param widgetId - Widget ID to add
     */
    function addBarWidget(section, widgetId) {
        if (!data.bar.widgets[section]) return

        var widgets = data.bar.widgets[section]
        widgets.push({ "id": widgetId })
        // Force update
        saveTimer.start()

        Logger.log("Settings", `Added widget "${widgetId}" to ${section} section`)
    }

    /**
     * Remove a widget from a section
     * @param section - "left", "center", or "right"
     * @param index - Widget index to remove
     */
    function removeBarWidget(section, index) {
        if (!data.bar.widgets[section]) return
        var widgets = data.bar.widgets[section]
        if (index < 0 || index >= widgets.length) return

        widgets.splice(index, 1)
        saveTimer.start()

        Logger.log("Settings", `Removed widget at index ${index} from ${section} section`)
    }

    // ==================== Settings Management Functions ====================

    /**
     * Save settings to disk
     * Helper function to centralize save logic
     */
    function saveSettings() {
        settingsFileView.writeAdapter()
    }

    /**
     * Upgrade settings from older versions to current schema
     * Runs automatically when settings are loaded
     */
    function upgradeSettings() {
        // Check if upgrade is needed
        if (adapter.settingsVersion >= currentSettingsVersion) {
            return
        }

        Logger.log("Settings", "Upgrading settings from v" + adapter.settingsVersion + " to v" + currentSettingsVersion)

        // Version 1 -> 2: No schema changes (validation improvements only)
        if (adapter.settingsVersion < 2) {
            adapter.settingsVersion = 2
            saveSettings()
            Logger.log("Settings", "Upgraded to v2")
        }

        // Version 2 -> 3: Add brightness, sessionMenu, network.updateInterval
        if (adapter.settingsVersion < 3) {
            // Add brightness settings if missing
            if (!adapter.brightness) {
                adapter.brightness = {
                    "pollInterval": 500,
                    "step": 5
                }
                Logger.log("Settings", "Added brightness settings")
            }

            // Add sessionMenu settings if missing
            if (!adapter.sessionMenu) {
                adapter.sessionMenu = {
                    "confirmationDelay": 9000,
                    "enableConfirmation": true,
                    "width": 280,
                    "height": 380
                }
                Logger.log("Settings", "Added sessionMenu settings")
            }

            // Add network.updateInterval if missing
            if (!adapter.network.updateInterval) {
                adapter.network.updateInterval = 30000
                Logger.log("Settings", "Added network.updateInterval")
            }

            adapter.settingsVersion = 3
            saveSettings()
            Logger.log("Settings", "Upgraded to v3")
        }

        // Future migrations go here
        // if (adapter.settingsVersion < 4) { ... }
    }

    /**
     * Validate settings and fix invalid values
     * Ensures data integrity and prevents crashes from corrupted settings
     */
    function validateSettings() {
        var needsSave = false

        // Validate UI settings
        if (adapter.ui.fontSize < 1 || adapter.ui.fontSize > 72) {
            Logger.warn("Settings", "Invalid fontSize (" + adapter.ui.fontSize + "), resetting to 7")
            adapter.ui.fontSize = 7
            needsSave = true
        }

        if (adapter.ui.iconSize < 1 || adapter.ui.iconSize > 100) {
            Logger.warn("Settings", "Invalid iconSize (" + adapter.ui.iconSize + "), resetting to 9")
            adapter.ui.iconSize = 9
            needsSave = true
        }

        // Validate bar settings
        if (adapter.bar.height < 10 || adapter.bar.height > 200) {
            Logger.warn("Settings", "Invalid bar height (" + adapter.bar.height + "), resetting to 22")
            adapter.bar.height = 22
            needsSave = true
        }

        var validPositions = ["top", "bottom", "left", "right"]
        if (!validPositions.includes(adapter.bar.position)) {
            Logger.warn("Settings", "Invalid bar position (" + adapter.bar.position + "), resetting to 'top'")
            adapter.bar.position = "top"
            needsSave = true
        }

        // Validate launcher settings
        if (adapter.launcher.maxResults < 1 || adapter.launcher.maxResults > 500) {
            Logger.warn("Settings", "Invalid launcher maxResults (" + adapter.launcher.maxResults + "), resetting to 50")
            adapter.launcher.maxResults = 50
            needsSave = true
        }

        // Validate audio settings
        if (adapter.audio.volumeStep < 1 || adapter.audio.volumeStep > 50) {
            Logger.warn("Settings", "Invalid audio volumeStep (" + adapter.audio.volumeStep + "), resetting to 5")
            adapter.audio.volumeStep = 5
            needsSave = true
        }

        // Validate brightness settings
        if (adapter.brightness.pollInterval < 100 || adapter.brightness.pollInterval > 5000) {
            Logger.warn("Settings", "Invalid brightness pollInterval (" + adapter.brightness.pollInterval + "), resetting to 500")
            adapter.brightness.pollInterval = 500
            needsSave = true
        }

        if (adapter.brightness.step < 1 || adapter.brightness.step > 50) {
            Logger.warn("Settings", "Invalid brightness step (" + adapter.brightness.step + "), resetting to 5")
            adapter.brightness.step = 5
            needsSave = true
        }

        // Validate network settings
        if (adapter.network.updateInterval < 5000 || adapter.network.updateInterval > 300000) {
            Logger.warn("Settings", "Invalid network updateInterval (" + adapter.network.updateInterval + "), resetting to 30000")
            adapter.network.updateInterval = 30000
            needsSave = true
        }

        // Validate sessionMenu settings
        if (adapter.sessionMenu.confirmationDelay < 1000 || adapter.sessionMenu.confirmationDelay > 60000) {
            Logger.warn("Settings", "Invalid sessionMenu confirmationDelay (" + adapter.sessionMenu.confirmationDelay + "), resetting to 9000")
            adapter.sessionMenu.confirmationDelay = 9000
            needsSave = true
        }

        if (adapter.sessionMenu.width < 200 || adapter.sessionMenu.width > 600) {
            Logger.warn("Settings", "Invalid sessionMenu width (" + adapter.sessionMenu.width + "), resetting to 280")
            adapter.sessionMenu.width = 280
            needsSave = true
        }

        if (adapter.sessionMenu.height < 200 || adapter.sessionMenu.height > 800) {
            Logger.warn("Settings", "Invalid sessionMenu height (" + adapter.sessionMenu.height + "), resetting to 380")
            adapter.sessionMenu.height = 380
            needsSave = true
        }

        // Save if any corrections were made
        if (needsSave) {
            Logger.log("Settings", "Validation complete, saving corrected settings")
            saveSettings()
        }
    }
}