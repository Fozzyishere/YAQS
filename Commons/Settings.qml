pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Settings version - increment when schema changes
    readonly property int currentSettingsVersion: 2

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

        // Trigger file loading
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

        // ==================== UI Theme ====================
        property JsonObject ui: JsonObject {
            // Spacing scale
            property int spacing0: 0
            property int spacingXxs: 1
            property int spacingXs: 2
            property int spacingS: 4
            property int spacingM: 8
            property int spacingL: 12
            property int spacingXl: 16
            property int spacing2xl: 24
            property int spacing3xl: 32

            // Radius scale
            property int radiusXs: 2
            property int radiusS: 4
            property int radiusM: 8
            property int radiusL: 12
            property int radiusXl: 16
            property int radiusFull: 9999

            // Animation durations (milliseconds)
            property int durationInstant: 0
            property int durationFast: 100
            property int durationNormal: 200
            property int durationSlow: 300

            // Opacity levels
            property real opacityNone: 0.0
            property real opacityLight: 0.25
            property real opacityMedium: 0.5
            property real opacityHeavy: 0.75
            property real opacityFull: 1.0

            // Typography
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 7
            property int fontSizeSmall: 5
            property int fontSizeLarge: 9
            property int fontSizeXlarge: 9

            // Icons
            property int iconSize: 9
        }

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

        // ==================== Colors ====================
        
        // 'm' prefix prevents QML from misinterpreting as signals (e.g., 'onPrimary')
        property JsonObject colors: JsonObject {
            // Primary color (Blue in Gruvbox)
            property color mPrimary: "#83a598"           // Bright blue
            property color mOnPrimary: "#1d2021"         // Dark text on primary
            property color mPrimaryContainer: "#458588"  // Neutral blue container
            property color mOnPrimaryContainer: "#fbf1c7" // Light text on container

            // Secondary color (Aqua in Gruvbox)
            property color mSecondary: "#8ec07c"          // Bright aqua
            property color mOnSecondary: "#1d2021"        // Dark text on secondary
            property color mSecondaryContainer: "#689d6a" // Neutral aqua container
            property color mOnSecondaryContainer: "#fbf1c7"

            // Tertiary color (Yellow for highlights)
            property color mTertiary: "#fabd2f"           // Bright yellow
            property color mOnTertiary: "#1d2021"         // Dark text on tertiary
            property color mTertiaryContainer: "#d79921"  // Neutral yellow container
            property color mOnTertiaryContainer: "#fbf1c7"

            // Error color (Red)
            property color mError: "#fb4934"              // Bright red
            property color mOnError: "#1d2021"            // Dark text on error
            property color mErrorContainer: "#cc241d"     // Neutral red container
            property color mOnErrorContainer: "#fbf1c7"

            // Surface colors (backgrounds)
            property color mSurface: "#1d2021"            // Main background (hard dark)
            property color mOnSurface: "#ebdbb2"          // Main text (light1)
            property color mSurfaceVariant: "#3c3836"     // Subtle variation (dark1)
            property color mOnSurfaceVariant: "#d5c4a1"   // Secondary text (light2)
            property color mSurfaceContainer: "#282828"   // Cards/dialogs (dark0)
            property color mSurfaceContainerLow: "#1d2021" // Lower elevation
            property color mSurfaceContainerHigh: "#504945" // Higher elevation (dark2)
            property color mSurfaceContainerHighest: "#665c54" // Highest elevation (dark3)

            // Outline/border colors
            property color mOutline: "#7c6f64"            // Main borders (dark4)
            property color mOutlineVariant: "#504945"     // Subtle borders (dark2)
            property color mShadow: "#000000"             // Shadows

            // Extension: Success color (not in standard M3)
            property color mSuccess: "#b8bb26"            // Bright green
            property color mOnSuccess: "#1d2021"
            property color mSuccessContainer: "#98971a"   // Neutral green
            property color mOnSuccessContainer: "#fbf1c7"

            // Extension: Warning color (not in standard M3)
            property color mWarning: "#fe8019"            // Bright orange
            property color mOnWarning: "#1d2021"
            property color mWarningContainer: "#d65d0e"   // Neutral orange
            property color mOnWarningContainer: "#fbf1c7"
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
        }

        // ==================== Audio Configuration ====================
        property JsonObject audio: JsonObject {
            property int volumeStep: 5
            property bool volumeOverdrive: false
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

        // Version 1 -> 2: Currently no new fields needed
        // This structure is in place for future migrations
        if (adapter.settingsVersion < 2) {
            // Example: Add new settings if they don't exist
            // if (!adapter.sessionMenu) {
            //     adapter.sessionMenu = {
            //         "confirmationDelay": 9000,
            //         "enableConfirmation": true
            //     }
            // }

            adapter.settingsVersion = 2
            saveSettings()
            Logger.log("Settings", "Upgraded to v2")
        }

        // Future migrations go here
        // if (adapter.settingsVersion < 3) { ... }
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

        // Save if any corrections were made
        if (needsSave) {
            Logger.log("Settings", "Validation complete, saving corrected settings")
            saveSettings()
        }
    }
}