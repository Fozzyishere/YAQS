pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Public API ===
  property var schemes: []                      // Array of scheme paths
  property bool scanning: false                  // Loading state
  property string schemesDirectory: Quickshell.shellDir + "/Assets/ColorScheme"
  property string colorsJsonFilePath: QsCommons.Settings.configDir + "colors.json"

  // === Connections ===
  // React to dark mode changes
  Connections {
    target: QsCommons.Settings.data.colorSchemes
    
    function onDarkModeChanged() {
      QsCommons.Logger.i("ColorScheme", "Detected dark mode change")
      
      if (!QsCommons.Settings.data.colorSchemes.useWallpaperColors 
          && QsCommons.Settings.data.colorSchemes.predefinedScheme) {
        // Re-apply current scheme to pick the right variant
        applyScheme(QsCommons.Settings.data.colorSchemes.predefinedScheme)
      }
      
      // TODO: Uncomment when ToastService available
      // const enabled = !!QsCommons.Settings.data.colorSchemes.darkMode
      // const label = enabled ? "Dark mode" : "Light mode"
      // ToastService.showNotice(label, "Enabled")
    }
  }

  // === Initialization ===
  function init() {
    QsCommons.Logger.i("ColorScheme", "Service started")
    loadColorSchemes()
  }

  // === Public Functions ===
  
  function loadColorSchemes() {
    QsCommons.Logger.d("ColorScheme", "Scanning for color schemes")
    scanning = true
    schemes = []
    // Use find command to locate all scheme JSON files
    findProcess.command = ["find", schemesDirectory, "-name", "*.json", "-type", "f"]
    findProcess.running = true
  }

  function getBasename(path) {
    if (!path) return ""
    
    var chunks = path.split("/")
    // Get the filename without extension
    var filename = chunks[chunks.length - 1]
    var schemeName = filename.replace(".json", "")
    
    // Convert back to display names for special cases
    if (schemeName === "Gruvbox") {
      return "Gruvbox"
    } else if (schemeName === "Ayu") {
      return "Ayu"
    } else if (schemeName === "Kanagawa") {
      return "Kanagawa"
    } else if (schemeName === "Tokyo Night") {
      return "Tokyo Night"
    }
    
    return schemeName
  }

  function resolveSchemePath(nameOrPath) {
    if (!nameOrPath) return ""
    
    if (nameOrPath.indexOf("/") !== -1) {
      return nameOrPath
    }
    
    // Handle special cases for predefined schemes
    var schemeName = nameOrPath.replace(".json", "")
    if (schemeName === "Gruvbox") {
      schemeName = "Gruvbox"
    } else if (schemeName === "Ayu") {
      schemeName = "Ayu"
    } else if (schemeName === "Kanagawa") {
      schemeName = "Kanagawa"
    } else if (schemeName === "Tokyo Night") {
      schemeName = "Tokyo-Night"
    }
    
    return schemesDirectory + "/" + schemeName + "/" + schemeName + ".json"
  }

  function applyScheme(nameOrPath) {
    // Force reload by bouncing the path
    var filePath = resolveSchemePath(nameOrPath)
    schemeReader.path = ""
    schemeReader.path = filePath
  }

  // === Internal Functions ===
  
  // Check if any templates are enabled (for AppThemeService integration)
  // TODO: Uncomment when AppThemeService is available
//   function hasEnabledTemplates() {
//     return null
//   }

  function writeColorsToDisk(obj) {
    function pick(o, a, b, fallback) {
      return (o && (o[a] || o[b])) || fallback
    }
    
    out.mPrimary = pick(obj, "mPrimary", "primary", out.mPrimary)
    out.mOnPrimary = pick(obj, "mOnPrimary", "onPrimary", out.mOnPrimary)
    out.mSecondary = pick(obj, "mSecondary", "secondary", out.mSecondary)
    out.mOnSecondary = pick(obj, "mOnSecondary", "onSecondary", out.mOnSecondary)
    out.mTertiary = pick(obj, "mTertiary", "tertiary", out.mTertiary)
    out.mOnTertiary = pick(obj, "mOnTertiary", "onTertiary", out.mOnTertiary)
    out.mError = pick(obj, "mError", "error", out.mError)
    out.mOnError = pick(obj, "mOnError", "onError", out.mOnError)
    out.mSurface = pick(obj, "mSurface", "surface", out.mSurface)
    out.mOnSurface = pick(obj, "mOnSurface", "onSurface", out.mOnSurface)
    out.mSurfaceVariant = pick(obj, "mSurfaceVariant", "surfaceVariant", out.mSurfaceVariant)
    out.mOnSurfaceVariant = pick(obj, "mOnSurfaceVariant", "onSurfaceVariant", out.mOnSurfaceVariant)
    out.mOutline = pick(obj, "mOutline", "outline", out.mOutline)
    out.mShadow = pick(obj, "mShadow", "shadow", out.mShadow)

    // Force a rewrite by updating the path
    colorsWriter.path = ""
    colorsWriter.path = colorsJsonFilePath
    colorsWriter.writeAdapter()
  }

  // === Process: Find Color Schemes ===
  Process {
    id: findProcess
    running: false

    onExited: function(exitCode) {
      if (exitCode === 0) {
        var output = stdout.text.trim()
        var files = output.split('\n').filter(function(line) {
          return line.length > 0
        })
        
        // Sort alphabetically by display name
        files.sort(function(a, b) {
          var nameA = getBasename(a).toLowerCase()
          var nameB = getBasename(b).toLowerCase()
          return nameA.localeCompare(nameB)
        })
        
        schemes = files
        scanning = false
        QsCommons.Logger.d("ColorScheme", "Listed " + schemes.length + " schemes")
        
        // Normalize stored scheme to basename and re-apply if necessary
        // This handles migration from old configs that stored full paths
        var stored = QsCommons.Settings.data.colorSchemes.predefinedScheme
        if (stored) {
          var basename = getBasename(stored)
          if (basename !== stored) {
            // Migrate from full path to display name
            QsCommons.Settings.data.colorSchemes.predefinedScheme = basename
          }
          if (!QsCommons.Settings.data.colorSchemes.useWallpaperColors) {
            applyScheme(basename)
          }
        }
      } else {
        QsCommons.Logger.e("ColorScheme", "Failed to find color scheme files")
        schemes = []
        scanning = false
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  // === FileView: Scheme Reader ===
  // Internal loader to read a scheme file
  FileView {
    id: schemeReader
    
    onLoaded: {
      try {
        var data = JSON.parse(text())
        var variant = data
        
        // If scheme provides dark/light variants, pick based on settings
        if (data && (data.dark || data.light)) {
          if (QsCommons.Settings.data.colorSchemes.darkMode) {
            variant = data.dark || data.light
          } else {
            variant = data.light || data.dark
          }
        }
        
        writeColorsToDisk(variant)
        QsCommons.Logger.i("ColorScheme", "Applying color scheme: " + getBasename(path))

        // TODO: Generate Matugen templates if any are enabled and setting allows it
        if (QsCommons.Settings.data.colorSchemes.generateTemplatesForPredefined 
            && hasEnabledTemplates()) {
          // TODO: implement when appThemeService is available
          // AppThemeService.generateFromPredefinedScheme(data)
        }
      } catch (e) {
        QsCommons.Logger.e("ColorScheme", "Failed to parse scheme JSON: " + path + " - " + e)
      }
    }
  }

  // === FileView: Colors Writer ===
  // Writer to colors.json using a JsonAdapter for safety
  FileView {
    id: colorsWriter
    path: colorsJsonFilePath
    
    onSaved: {
      // Logger.d("ColorScheme", "Colors saved")
    }
    
    JsonAdapter {
      id: out
      property color mPrimary: "#000000"
      property color mOnPrimary: "#000000"
      property color mSecondary: "#000000"
      property color mOnSecondary: "#000000"
      property color mTertiary: "#000000"
      property color mOnTertiary: "#000000"
      property color mError: "#ff0000"
      property color mOnError: "#000000"
      property color mSurface: "#ffffff"
      property color mOnSurface: "#000000"
      property color mSurfaceVariant: "#cccccc"
      property color mOnSurfaceVariant: "#333333"
      property color mOutline: "#444444"
      property color mShadow: "#000000"
    }
  }
}

