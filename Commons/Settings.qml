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

    // osd (on-screen display for volume/brightness)
    property JsonObject osd: JsonObject {
      property bool enabled: true
      property string location: "bottom"  // "top", "top_right", "top_left", "bottom", "bottom_right", "bottom_left", "left", "right"
      property list<string> monitors: []     // Empty = all monitors
      property bool overlayLayer: false      // Use Overlay layer vs Top layer
      property int autoHideMs: 2000          // Auto-hide delay in milliseconds
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

    // Wallpaper

    // Manages desktop wallpaper display and rotation across monitors.
    // To change wallpaper, edit the "monitors" array with your screen name and wallpaper path.
    // Example settings.json:
    //   "wallpaper": {
    //     "enabled": true,
    //     "monitors": [
    //       { "name": "DP-1", "wallpaper": "/home/user/Pictures/wallpaper.jpg" },
    //       { "name": "HDMI-A-1", "wallpaper": "/home/user/Pictures/other.png" }
    //     ]
    //   }
    // Run `quickshell -l` or check compositor output to find your screen names.
    property JsonObject wallpaper: JsonObject {
      // Master toggle - when false, no wallpaper panels are created
      property bool enabled: true

      // Directory to scan for wallpaper images (used by random rotation and future UI picker)
      // Supports ~ expansion: "~/Pictures/Wallpapers" → "/home/user/Pictures/Wallpapers"
      property string directory: Settings.defaultWallpapersDirectory

      // Fallback wallpaper when a monitor has no wallpaper set in the monitors array
      property string defaultWallpaper: Quickshell.shellDir + "/Assets/Wallpaper/dark.jpeg"

      // How the wallpaper image fills the screen:
      //   "crop"    - Fill screen, crop edges (default, no letterboxing)
      //   "fit"     - Fit entire image, may show background color bars
      //   "stretch" - Stretch to fill (distorts aspect ratio)
      //   "center"  - Center at original size (may not cover screen)
      property string fillMode: "center"

      // When true, each monitor can have its own wallpaper directory.
      // When false, all monitors share the main "directory" setting.
      property bool enableMultiMonitorDirectories: false

      // Automatic wallpaper rotation - picks random wallpaper from directory
      property bool randomEnabled: false
      property int randomIntervalSec: 300  // Rotation interval in seconds (300 = 5 minutes)

      // Per-monitor wallpaper configuration. This is where selected wallpapers are stored.
      // Each object: { "name": "SCREEN_NAME", "directory": "optional/path", "wallpaper": "/full/path/to/image.jpg" }
      // The "name" must match your monitor's name (e.g., "DP-1", "eDP-1", "HDMI-A-1")
      // The "directory" is optional and only used when enableMultiMonitorDirectories is true
      // The "wallpaper" is the full path to the currently selected wallpaper for that monitor
      property list<var> monitors: []

      // Transition animation when changing wallpapers:
      //   "none" - Instant switch (no animation)
      //   "fade" - Crossfade between old and new wallpaper
      property string transitionType: "fade"

      // Duration of fade transition in milliseconds (ignored when transitionType is "none")
      property int transitionDuration: 500
    }

    // location (weather and geolocation)
    property JsonObject location: JsonObject {
      property string name: Settings.defaultLocation
      property bool weatherEnabled: true
      property bool useFahrenheit: false
      property bool use12hourFormat: false
      property bool showWeekNumberInCalendar: false
      property bool showCalendarEvents: true
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
