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
      property string predefinedScheme: "YAQS Default"
      property bool darkMode: true
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
