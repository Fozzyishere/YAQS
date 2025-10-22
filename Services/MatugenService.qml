pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "../Commons"

/**
 * MatugenService - Material You color generation service
 *
 * Generates Material Design 3 color palettes from wallpaper images using matugen.
 * Uses QuickShell Process API for execution and file reading.
 *
 * Features:
 * - Dynamic color generation from wallpapers
 * - Three regeneration modes: auto, manual, scheduled
 * - GTK/Qt theme integration via matugen
 * - JSON-based color palette storage
 * - Runtime color updates without shell restart
 */
Singleton {
    id: root

    // ============================================================================
    // PUBLIC PROPERTIES
    // ============================================================================

    property bool initialized: false
    property bool autoReload: Settings.data.theme?.autoReload ?? true
    property string currentWallpaper: ""
    property var currentColors: ({})  // Stores colors object from matugen JSON
    property string regenerationMode: Settings.data.theme?.regenerationMode ?? "auto"
    property int regenerationInterval: Settings.data.theme?.autoRegenerationInterval ?? 3600000

    // ============================================================================
    // SIGNALS
    // ============================================================================

    signal themeGenerated(var colors)
    signal themeGenerationFailed(string error)
    signal colorsUpdated(var colors)

    // ============================================================================
    // MATUGEN PROCESS - Uses QuickShell Process API
    // ============================================================================

    property Process matugenProcess: Process {
        command: []
        running: false

        // Capture stdout for debugging
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                Logger.log("MatugenService", "Matugen:", data)
            }
        }

        // Capture stderr for errors
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                Logger.warn("MatugenService", "Matugen stderr:", data)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Logger.log("MatugenService", "Matugen completed successfully")
                loadGeneratedColors()  // Load the JSON file
            } else {
                const error = "Matugen failed with exit code: " + exitCode
                Logger.error("MatugenService", error)
                themeGenerationFailed(error)
            }
        }
    }

    // ============================================================================
    // FILE READER PROCESS - Uses Process + cat for file reading
    // ============================================================================

    property Process catProcess: Process {
        command: []
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // Parse the JSON output from matugen
                    const jsonData = JSON.parse(this.text)
                    currentColors = jsonData.colors  // Extract colors object

                    Logger.log("MatugenService", "Loaded", Object.keys(currentColors).length, "color variants")
                    Logger.log("MatugenService", "Primary color:", currentColors.primary?.default)
                    Logger.log("MatugenService", "Source color:", currentColors.source_color?.default)

                    // Update Color.qml with new colors
                    updateColorTokens()
                    themeGenerated(currentColors)

                } catch (error) {
                    Logger.error("MatugenService", "JSON parse error:", error)
                    themeGenerationFailed("Failed to parse matugen JSON: " + error.toString())
                }
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                Logger.error("MatugenService", "Cat error:", data)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Logger.error("MatugenService", "Failed to read JSON file, exit code:", exitCode)
                themeGenerationFailed("Failed to read generated colors")
            }
        }
    }

    // ============================================================================
    // SCHEDULED REGENERATION TIMER
    // ============================================================================

    Timer {
        id: regenerationTimer
        interval: root.regenerationInterval
        running: root.regenerationMode === "scheduled" && root.initialized
        repeat: true

        onTriggered: {
            if (root.currentWallpaper) {
                Logger.log("MatugenService", "Scheduled regeneration triggered")
                root.generateTheme(root.currentWallpaper)
            }
        }
    }

    // ============================================================================
    // INITIALIZATION
    // ============================================================================

    function init() {
        if (initialized) {
            Logger.warn("MatugenService", "Already initialized")
            return
        }

        Logger.log("MatugenService", "Initializing...")
        Logger.log("MatugenService", "Regeneration mode:", regenerationMode)
        Logger.log("MatugenService", "Auto reload:", autoReload)

        setupConnections()
        initialized = true

        Logger.log("MatugenService", "Initialization complete")
    }

    function setupConnections() {
        // Future: Connect to WallpaperService when available
        // if (typeof WallpaperService !== "undefined") {
        //     WallpaperService.wallpaperChanged.connect(generateTheme)
        // }
    }

    // ============================================================================
    // THEME GENERATION - Uses Process instead of execDetached()
    // ============================================================================

    function generateTheme(wallpaper) {
        if (!wallpaper || wallpaper === "") {
            Logger.error("MatugenService", "No wallpaper path provided")
            themeGenerationFailed("No wallpaper path provided")
            return
        }

        if (matugenProcess.running) {
            Logger.warn("MatugenService", "Matugen already running, skipping")
            return
        }

        try {
            Logger.log("MatugenService", "Generating theme for:", wallpaper)
            currentWallpaper = wallpaper

            // Build matugen command
            const outputPath = "/tmp/yaqs-matugen-colors.json"
            const mode = Settings.data.theme?.colorMode ?? "dark"
            const scheme = Settings.data.theme?.schemeType ?? "scheme-tonal-spot"

            // Use sh -c for output redirection (matugen has no --output flag)
            matugenProcess.command = [
                "sh", "-c",
                "matugen image '" + wallpaper + "' --json hex --mode " + mode + " --type " + scheme + " > " + outputPath
            ]

            Logger.log("MatugenService", "Command:", matugenProcess.command.join(" "))
            Logger.log("MatugenService", "Running matugen...")
            matugenProcess.running = true

        } catch (error) {
            Logger.error("MatugenService", "Failed to start matugen:", error)
            themeGenerationFailed(error.toString())
        }
    }

    // ============================================================================
    // COLOR LOADING - Uses Process + cat instead of readFile()
    // ============================================================================

    function loadGeneratedColors() {
        if (catProcess.running) {
            Logger.warn("MatugenService", "Color load already in progress")
            return
        }

        try {
            const outputPath = "/tmp/yaqs-matugen-colors.json"

            Logger.log("MatugenService", "Loading colors from:", outputPath)

            catProcess.command = ["cat", outputPath]
            catProcess.running = true

        } catch (error) {
            Logger.error("MatugenService", "Failed to read colors:", error)
            themeGenerationFailed(error.toString())
        }
    }

    // ============================================================================
    // COLOR TOKEN UPDATES
    // ============================================================================

    function updateColorTokens() {
        if (!currentColors || Object.keys(currentColors).length === 0) {
            Logger.error("MatugenService", "No colors to update")
            return
        }

        try {
            Logger.log("MatugenService", "Updating Color.qml tokens...")

            // Update Color.qml with matugen palette (uses .default values)
            Color.updateFromMatugen({
                // Primary
                mPrimary: currentColors.primary?.default || Color.mPrimary,
                mOnPrimary: currentColors.on_primary?.default || Color.mOnPrimary,
                mPrimaryContainer: currentColors.primary_container?.default || Color.mPrimaryContainer,
                mOnPrimaryContainer: currentColors.on_primary_container?.default || Color.mOnPrimaryContainer,

                // Secondary
                mSecondary: currentColors.secondary?.default || Color.mSecondary,
                mOnSecondary: currentColors.on_secondary?.default || Color.mOnSecondary,
                mSecondaryContainer: currentColors.secondary_container?.default || Color.mSecondaryContainer,
                mOnSecondaryContainer: currentColors.on_secondary_container?.default || Color.mOnSecondaryContainer,

                // Tertiary
                mTertiary: currentColors.tertiary?.default || Color.mTertiary,
                mOnTertiary: currentColors.on_tertiary?.default || Color.mOnTertiary,
                mTertiaryContainer: currentColors.tertiary_container?.default || Color.mTertiaryContainer,
                mOnTertiaryContainer: currentColors.on_tertiary_container?.default || Color.mOnTertiaryContainer,

                // Error
                mError: currentColors.error?.default || Color.mError,
                mOnError: currentColors.on_error?.default || Color.mOnError,
                mErrorContainer: currentColors.error_container?.default || Color.mErrorContainer,
                mOnErrorContainer: currentColors.on_error_container?.default || Color.mOnErrorContainer,

                // Surface/Background
                mBackground: currentColors.background?.default || Color.mBackground,
                mOnBackground: currentColors.on_background?.default || Color.mOnBackground,
                mSurface: currentColors.surface?.default || Color.mSurface,
                mOnSurface: currentColors.on_surface?.default || Color.mOnSurface,
                mSurfaceVariant: currentColors.surface_variant?.default || Color.mSurfaceVariant,
                mOnSurfaceVariant: currentColors.on_surface_variant?.default || Color.mOnSurfaceVariant,
                mSurfaceContainer: currentColors.surface_container?.default || Color.mSurfaceContainer,
                mSurfaceContainerLow: currentColors.surface_container_low?.default || Color.mSurfaceContainerLow,
                mSurfaceContainerHigh: currentColors.surface_container_high?.default || Color.mSurfaceContainerHigh,
                mSurfaceContainerHighest: currentColors.surface_container_highest?.default || Color.mSurfaceContainerHighest,

                // Outline
                mOutline: currentColors.outline?.default || Color.mOutline,
                mOutlineVariant: currentColors.outline_variant?.default || Color.mOutlineVariant,
                mShadow: currentColors.shadow?.default || Color.mShadow
            })

            colorsUpdated(currentColors)
            Logger.log("MatugenService", "Color tokens updated successfully")

        } catch (error) {
            Logger.error("MatugenService", "Failed to update color tokens:", error)
            themeGenerationFailed(error.toString())
        }
    }

    // ============================================================================
    // MODE MANAGEMENT
    // ============================================================================

    function toggleRegenerationMode() {
        const modes = ["auto", "manual", "scheduled"]
        const currentIndex = modes.indexOf(regenerationMode)
        const nextIndex = (currentIndex + 1) % modes.length
        regenerationMode = modes[nextIndex]

        if (Settings.data.theme) {
            Settings.data.theme.regenerationMode = regenerationMode
            Settings.saveSettings()
        }

        Logger.log("MatugenService", "Regeneration mode changed to:", regenerationMode)
    }

    function setRegenerationMode(mode) {
        const validModes = ["auto", "manual", "scheduled"]
        if (!validModes.includes(mode)) {
            Logger.error("MatugenService", "Invalid mode:", mode)
            return
        }

        regenerationMode = mode

        if (Settings.data.theme) {
            Settings.data.theme.regenerationMode = regenerationMode
            Settings.saveSettings()
        }

        Logger.log("MatugenService", "Regeneration mode set to:", mode)
    }

    // ============================================================================
    // UTILITY FUNCTIONS
    // ============================================================================

    function getThemeInfo() {
        return {
            "wallpaper": currentWallpaper,
            "hasColors": Object.keys(currentColors).length > 0,
            "colorCount": Object.keys(currentColors).length,
            "mode": regenerationMode,
            "autoReload": autoReload,
            "primaryColor": currentColors.primary?.default || "N/A",
            "sourceColor": currentColors.source_color?.default || "N/A",
            "isGenerating": isGenerating()
        }
    }

    function isGenerating() {
        return matugenProcess.running || catProcess.running
    }
}
