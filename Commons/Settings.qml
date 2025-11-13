pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // Used to access via Settings.data.xxx.yyy
  readonly property alias data: adapter
  property bool isLoaded: false
  property bool directoriesCreated: false
  property int settingsVersion: 1
  property bool isDebug: Quickshell.env("YAQS_DEBUG") === "1"

  // Define our app directories
  // Default config directory: ~/.config/yaqs
  // Default cache directory: ~/.cache/yaqs
  property string shellName: "yaqs"
  property string configDir: Quickshell.env("YAQS_CONFIG_DIR") || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/" + shellName + "/"
  property string cacheDir: Quickshell.env("YAQS_CACHE_DIR") || (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/" + shellName + "/"
  property string cacheDirImages: cacheDir + "images/"
  property string cacheDirImagesWallpapers: cacheDir + "images/wallpapers/"
  property string cacheDirImagesNotifications: cacheDir + "images/notifications/"
  property string settingsFile: Quickshell.env("YAQS_SETTINGS_FILE") || (configDir + "settings.json")

  property string defaultLocation: "Tokyo"
  property string defaultAvatar: Quickshell.env("HOME") + "/.face"
  property string defaultVideosDirectory: Quickshell.env("HOME") + "/Videos"
  property string defaultWallpapersDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"

  // Signal emitted when settings are loaded
  signal settingsLoaded
  signal settingsSaved

  // -----------------------------------------------------
  // Ensure directories exist before FileView tries to read files
  Component.onCompleted: {
    // ensure settings dir exists
    Quickshell.execDetached(["mkdir", "-p", configDir])
    Quickshell.execDetached(["mkdir", "-p", cacheDir])

    Quickshell.execDetached(["mkdir", "-p", cacheDirImagesWallpapers])
    Quickshell.execDetached(["mkdir", "-p", cacheDirImagesNotifications])

    // Mark directories as created and trigger file loading
    directoriesCreated = true

    // Patch-in the local default, resolved to user's home
    adapter.general.avatarImage = defaultAvatar

    // Set the adapter to the settingsFileView to trigger the real settings load
    settingsFileView.adapter = adapter
  }

  // Don't write settings to disk immediately
  // This avoid excessive IO when a variable changes rapidly (ex: sliders)
  Timer {
    id: saveTimer
    running: false
    interval: 1000
    onTriggered: {
      root.saveImmediate()
    }
  }

  FileView {
    id: settingsFileView
    path: directoriesCreated ? settingsFile : undefined
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: saveTimer.start()

    // Trigger initial load when path changes from empty to actual path
    onPathChanged: {
      if (path !== undefined) {
        reload()
      }
    }
    onLoaded: function () {
      if (!isLoaded) {
        console.log("[YAQS] Settings loaded")

        upgradeSettingsData()
        isLoaded = true

        // Emit the signal
        root.settingsLoaded()

        // Finally, update our local settings version
        adapter.settingsVersion = settingsVersion
      }
    }
    onLoadFailed: function (error) {
      if (error.toString().includes("No such file") || error === 2) {
        // File doesn't exist, create it with default values
        writeAdapter()
      }
    }
  }

  JsonAdapter {
    id: adapter

    property int settingsVersion: root.settingsVersion
    property bool setupCompleted: false

    // general
    property JsonObject general: JsonObject {
      property string avatarImage: ""
      property real scaleRatio: 1.0
      property real radiusRatio: 1.0
      property real animationSpeed: 1.0
      property bool animationDisabled: false
      property string language: "en"
    }

    // bar
    property JsonObject bar: JsonObject {
      property string position: "top" // "top", "bottom", "left", or "right"
      property real backgroundOpacity: 1.0
      property list<string> monitors: []
      property string density: "default" // "compact", "default", "comfortable"
      property bool floating: false
      property real marginVertical: 0.25
      property real marginHorizontal: 0.25

      // Widget configuration for modular bar system
      property JsonObject widgets
      widgets: JsonObject {
        property list<var> left: []
        property list<var> center: []
        property list<var> right: []
      }
    }

    // colorSchemes
    property JsonObject colorSchemes: JsonObject {
      property bool useWallpaperColors: false
      property string predefinedScheme: "Gruvbox"  // Default fallback when not using wallpaper colors
      property bool darkMode: true
      property bool generateTemplatesForPredefined: false      // Trigger AppThemeService
      property string matugenSchemeType: "scheme-tonal-spot"  // For AppThemeService
      
      // DarkModeService scheduling
      property string schedulingMode: "manual"  // "manual" or "location"
      property string manualSunrise: "06:00"
      property string manualSunset: "18:00"
    }

    // templates (for AppThemeService integration in Phase 2.5.3)
    property JsonObject templates: JsonObject {
      property bool gtk: false
      property bool qt: false
      property bool kcolorscheme: false
      property bool kitty: false
      property bool foot: false
      property bool ghostty: false
      property bool btop: false
      property bool hyprland: false
      property bool pywalfox: false
      property bool discord_vesktop: false
      property bool discord_webcord: false
      property bool discord_armcord: false
      property bool discord_vencord: false
      property bool discord_equibop: false
      property bool discord_lightcord: false
      property bool discord_dorion: false
      property bool enableUserTemplates: false
    }

    // ui
    property JsonObject ui: JsonObject {
      property string fontDefault: "Roboto"
      property string fontFixed: "DejaVu Sans Mono"
      property real fontDefaultScale: 1.0
      property real fontFixedScale: 1.0
      property bool tooltipsEnabled: true
      property bool panelsOverlayLayer: true
    }

    // audio
    property JsonObject audio: JsonObject {
      property real volumeStep: 5.0         // Volume step percentage (0-100)
      property bool volumeOverdrive: false  // Allow volume >100% (up to 150%)
      property list<string> mprisBlacklist: []  // Player identities to ignore (TODO: Add sample list later)
      property string preferredPlayer: ""       // Preferred player identity
    }

    // brightness
    property JsonObject brightness: JsonObject {
      property real step: 5.0  // Brightness step percentage (0-100)
    }

    // network
    property JsonObject network: JsonObject {
      property bool wifiEnabled: true
    }

    // placeholder for launcher settings (TODO: Change when implemented later)
    property JsonObject appLauncher: JsonObject {
      property bool enableClipboardHistory: false  // Enable clipboard history in launcher
    }

    // notifications
    property JsonObject notifications: JsonObject {
      property bool doNotDisturb: false
      property bool respectExpireTimeout: true
      property int lowUrgencyDuration: 3
      property int normalUrgencyDuration: 5
      property int criticalUrgencyDuration: 10
      property string location: "top_right"  // "top", "top_right", "top_left", "bottom", "bottom_right", "bottom_left"
      property bool overlayLayer: false      // Use Overlay layer (above everything) vs Top layer
      property list<string> monitors: []     // Empty = all monitors
    }

    // calendar
    property JsonObject calendar: JsonObject {
      property bool enabled: true
      property bool autoRefresh: true
      property int refreshInterval: 300000      // 5 minutes in milliseconds
      property int daysAhead: 31                // Days to load ahead
      property int daysBehind: 14               // Days to load behind
      property bool showInControlCenter: true   // Show calendar in control center
      property bool showEventIndicators: true   // Show event dots on calendar dates (for future UI)
    }

    // wallpaper
    property JsonObject wallpaper: JsonObject {
      property string directory: Settings.defaultWallpapersDirectory
      property string defaultWallpaper: Quickshell.shellDir + "/Assets/Wallpaper/dark.jpeg"
      property string fillMode: "crop"  // "center", "crop", "fit", "stretch"
      property bool enableMultiMonitorDirectories: false
      property bool randomEnabled: false
      property int randomIntervalSec: 300  // 5 minutes (300 seconds)
      property list<var> monitors: []  // [{name: string, directory: string, wallpaper: string}]
      
      // TODO: Add transition settings when implementing animated wallpaper changes
      // property string transition: "none"  // Insert transition effects heere
      // property int transitionDuration: 1000  // milliseconds
    }
  }

  // -----------------------------------------------------
  // Function to preprocess paths by expanding "~" to user's home directory
  function preprocessPath(path) {
    if (typeof path !== "string" || path === "") {
      return path
    }

    // Expand "~" to user's home directory
    if (path.startsWith("~/")) {
      return Quickshell.env("HOME") + path.substring(1)
    } else if (path === "~") {
      return Quickshell.env("HOME")
    }

    return path
  }

  // -----------------------------------------------------
  // Public function to trigger immediate settings saving
  function saveImmediate() {
    settingsFileView.writeAdapter()
    root.settingsSaved() // Emit signal after saving
  }

  // -----------------------------------------------------
  // Function to upgrade settings data for version migrations
  function upgradeSettingsData() {
    // Placeholder for future migrations
    // if (adapter.settingsVersion < 2) {
    //   // Migration code here
    // }
  }
}
