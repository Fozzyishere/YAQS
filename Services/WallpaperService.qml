pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

Singleton {
  id: root

  readonly property string defaultDirectory: 
    QsCommons.Settings.preprocessPath(QsCommons.Settings.data.wallpaper.directory)

  readonly property ListModel fillModeModel: ListModel {}

  // TODO: Add transitions feature when implementing Background module animations
  // readonly property ListModel transitionsModel: ListModel {}
  // readonly property var allTransitions: Array.from({
  //   "length": transitionsModel.count
  // }, (_, i) => transitionsModel.get(i).key).filter(key => key !== "random" && key !== "none")

  property var wallpaperLists: ({})
  property int scanningCount: 0
  readonly property bool scanning: (scanningCount > 0)

  // Cache for current wallpapers
  property var currentWallpapers: ({})

  property bool isInitialized: false

  // Signals for UI updates
  signal wallpaperChanged(string screenName, string path)
  signal wallpaperDirectoryChanged(string screenName, string directory)
  signal wallpaperListChanged(string screenName, int count)

  Connections {
    target: QsCommons.Settings.data.wallpaper
    
    function onDirectoryChanged() {
      root.refreshWallpapersList()
        // Emit directory change signals for monitors using the default directory
      if (!QsCommons.Settings.data.wallpaper.enableMultiMonitorDirectories) {
        // All monitors use the main directory
        for (var i = 0; i < Quickshell.screens.length; i++) {
          root.wallpaperDirectoryChanged(Quickshell.screens[i].name, root.defaultDirectory)
        }
      } else {
        // Only monitors without custom directories are affected
        for (var i = 0; i < Quickshell.screens.length; i++) {
          var screenName = Quickshell.screens[i].name
          var monitor = root.getMonitorConfig(screenName)
          if (!monitor || !monitor.directory) {
            root.wallpaperDirectoryChanged(screenName, root.defaultDirectory)
          }
        }
      }
    }

    function onEnableMultiMonitorDirectoriesChanged() {
      root.refreshWallpapersList()
      // Notify all monitors about potential directory changes
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name
        root.wallpaperDirectoryChanged(screenName, root.getMonitorDirectory(screenName))
      }
    }

    function onRandomEnabledChanged() {
      root.toggleRandomWallpaper()
    }

    function onRandomIntervalSecChanged() {
      root.restartRandomWallpaperTimer()
    }

    // Watch for changes to the monitors array (e.g., when settings.json is edited externally)
    function onMonitorsChanged() {
      root._syncWallpapersFromSettings()
    }
  }

  // ========================================
  // Public API
  // ========================================

  function init() {
    QsCommons.Logger.i("Wallpaper", "Service started")

    // Populate fill mode model (no I18n - English literals only)
    fillModeModel.append({key: "center", name: "Center", uniform: 0.0})
    fillModeModel.append({key: "crop", name: "Crop (Fill)", uniform: 1.0})
    fillModeModel.append({key: "fit", name: "Fit (Contain)", uniform: 2.0})
    fillModeModel.append({key: "stretch", name: "Stretch", uniform: 3.0})

    // TODO: Populate transitions model when implementing animated transitions
    // transitionsModel.append({key: "none", name: "None"})
    // transitionsModel.append({key: "random", name: "Random"})
    // transitionsModel.append({key: "fade", name: "Fade"})
    // transitionsModel.append({key: "disc", name: "Disc"})
    // transitionsModel.append({key: "stripes", name: "Stripes"})
    // transitionsModel.append({key: "wipe", name: "Wipe"})

    // Rebuild cache from settings
    currentWallpapers = ({})
    var monitors = QsCommons.Settings.data.wallpaper.monitors || []
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name && monitors[i].wallpaper) {
        currentWallpapers[monitors[i].name] = monitors[i].wallpaper
      }
    }

    isInitialized = true
  }

  function getFillModeUniform() {
    for (var i = 0; i < fillModeModel.count; i++) {
      const mode = fillModeModel.get(i)
      if (mode.key === QsCommons.Settings.data.wallpaper.fillMode) {
        return mode.uniform
      }
    }
    // Fallback to crop
    return 1.0
  }

  // Get specific monitor wallpaper configuration
  function getMonitorConfig(screenName) {
    var monitors = QsCommons.Settings.data.wallpaper.monitors
    if (monitors !== undefined) {
      for (var i = 0; i < monitors.length; i++) {
        if (monitors[i].name !== undefined && monitors[i].name === screenName) {
          return monitors[i]
        }
      }
    }
  }

  // Get specific monitor directory
  function getMonitorDirectory(screenName) {
    if (!QsCommons.Settings.data.wallpaper.enableMultiMonitorDirectories) {
      return root.defaultDirectory
    }

    var monitor = getMonitorConfig(screenName)
    if (monitor !== undefined && monitor.directory !== undefined) {
      return QsCommons.Settings.preprocessPath(monitor.directory)
    }

    // Fall back to the main/single directory
    return root.defaultDirectory
  }

  // Set specific monitor directory
  function setMonitorDirectory(screenName, directory) {
    var monitors = QsCommons.Settings.data.wallpaper.monitors || []
    var found = false

    // Create a new array with updated values
    var newMonitors = monitors.map(function (monitor) {
      if (monitor.name === screenName) {
        found = true
        return {
          "name": screenName,
          "directory": directory,
          "wallpaper": monitor.wallpaper || ""
        }
      }
      return monitor
    })

    if (!found) {
      newMonitors.push({
        "name": screenName,
        "directory": directory,
        "wallpaper": ""
      })
    }

    // Update Settings with new array to ensure proper persistence
    QsCommons.Settings.data.wallpaper.monitors = newMonitors.slice()
    root.wallpaperDirectoryChanged(screenName, QsCommons.Settings.preprocessPath(directory))
  }

  // Get specific monitor wallpaper - from cache
  function getWallpaper(screenName) {
    return currentWallpapers[screenName] || QsCommons.Settings.data.wallpaper.defaultWallpaper
  }

  function changeWallpaper(path, screenName) {
    if (screenName !== undefined) {
      _setWallpaper(screenName, path)
    } else {
      // If no screenName specified, change for all screens
      for (var i = 0; i < Quickshell.screens.length; i++) {
        _setWallpaper(Quickshell.screens[i].name, path)
      }
    }
  }

  // Sync wallpapers from settings (called when monitors array changes externally)
  function _syncWallpapersFromSettings() {
    var monitors = QsCommons.Settings.data.wallpaper.monitors || []
    
    // Check each monitor in settings for changes
    for (var i = 0; i < monitors.length; i++) {
      var monitor = monitors[i]
      if (monitor.name && monitor.wallpaper) {
        var cachedPath = currentWallpapers[monitor.name] || ""
        
        // If wallpaper path changed, update cache and emit signal
        if (cachedPath !== monitor.wallpaper) {
          QsCommons.Logger.d("Wallpaper", "External change detected for " + monitor.name + ": " + monitor.wallpaper)
          currentWallpapers[monitor.name] = monitor.wallpaper
          root.wallpaperChanged(monitor.name, monitor.wallpaper)
        }
      }
    }
  }

  function _setWallpaper(screenName, path) {
    if (path === "" || path === undefined) {
      return
    }

    if (screenName === undefined) {
      QsCommons.Logger.w("Wallpaper", "_setWallpaper called with no screen specified")
      return
    }

    // Check if wallpaper actually changed
    var oldPath = currentWallpapers[screenName] || ""
    var wallpaperChanged = (oldPath !== path)

    if (!wallpaperChanged) {
      // No change needed
      return
    }

    // Update cache directly
    currentWallpapers[screenName] = path

    // Update Settings - still need immutable update for Settings persistence
    // The slice() ensures Settings detects the change and saves properly
    var monitors = QsCommons.Settings.data.wallpaper.monitors || []
    var found = false

    var newMonitors = monitors.map(function (monitor) {
      if (monitor.name === screenName) {
        found = true
        return {
          "name": screenName,
          "directory": monitor.directory || getMonitorDirectory(screenName),
          "wallpaper": path
        }
      }
      return monitor
    })

    if (!found) {
      newMonitors.push({
        "name": screenName,
        "directory": getMonitorDirectory(screenName),
        "wallpaper": path
      })
    }

    QsCommons.Settings.data.wallpaper.monitors = newMonitors.slice()

    // Emit signal for this specific wallpaper change
    root.wallpaperChanged(screenName, path)

    // Restart the random wallpaper timer
    if (randomWallpaperTimer.running) {
      randomWallpaperTimer.restart()
    }
  }

  function setRandomWallpaper() {
    QsCommons.Logger.d("Wallpaper", "Setting random wallpaper")

    if (QsCommons.Settings.data.wallpaper.enableMultiMonitorDirectories) {
      // Pick a random wallpaper per screen
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name
        var wallpaperList = getWallpapersList(screenName)

        if (wallpaperList.length > 0) {
          var randomIndex = Math.floor(Math.random() * wallpaperList.length)
          var randomPath = wallpaperList[randomIndex]
          changeWallpaper(randomPath, screenName)
        }
      }
    } else {
      // Pick a random wallpaper common to all screens
      // Use the first screen's list
      if (Quickshell.screens.length > 0) {
        var wallpaperList = getWallpapersList(Quickshell.screens[0].name)
        if (wallpaperList.length > 0) {
          var randomIndex = Math.floor(Math.random() * wallpaperList.length)
          var randomPath = wallpaperList[randomIndex]
          changeWallpaper(randomPath, undefined)  // Apply to all
        }
      }
    }
  }

  function toggleRandomWallpaper() {
    QsCommons.Logger.d("Wallpaper", "Toggling random wallpaper")
    if (QsCommons.Settings.data.wallpaper.randomEnabled) {
      restartRandomWallpaperTimer()
      setRandomWallpaper()  // Set immediately
    }
  }

  function restartRandomWallpaperTimer() {
    if (QsCommons.Settings.data.wallpaper.randomEnabled) {
      randomWallpaperTimer.restart()
    }
  }

  function getWallpapersList(screenName) {
    if (screenName !== undefined && wallpaperLists[screenName] !== undefined) {
      return wallpaperLists[screenName]
    }
    return []
  }

  function refreshWallpapersList() {
    QsCommons.Logger.d("Wallpaper", "Refreshing wallpaper lists")
    scanningCount = 0

    // Force refresh by toggling the folder property on each FolderListModel
    for (var i = 0; i < wallpaperScanners.count; i++) {
      var scanner = wallpaperScanners.objectAt(i)
      if (scanner) {
        var currentFolder = scanner.folder
        scanner.folder = ""
        scanner.folder = currentFolder
      }
    }
  }

  // ========================================
  // Internal Components
  // ========================================

  Timer {
    id: randomWallpaperTimer
    interval: QsCommons.Settings.data.wallpaper.randomIntervalSec * 1000
    running: QsCommons.Settings.data.wallpaper.randomEnabled
    repeat: true
    onTriggered: setRandomWallpaper()
    triggeredOnStart: false
  }

  // Instantiator (not Repeater) to create FolderListModel for each monitor
  Instantiator {
    id: wallpaperScanners
    model: Quickshell.screens
    
    delegate: FolderListModel {
      property string screenName: modelData.name
      property string currentDirectory: root.getMonitorDirectory(screenName)

      folder: "file://" + currentDirectory
      nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"]
      showDirs: false
      sortField: FolderListModel.Name

      // Watch for directory changes via property binding
      onCurrentDirectoryChanged: {
        folder = "file://" + currentDirectory
      }

      Component.onCompleted: {
        // Connect to directory change signal
        root.wallpaperDirectoryChanged.connect(function (screen, directory) {
          if (screen === screenName) {
            currentDirectory = directory
          }
        })
      }

      onStatusChanged: {
        if (status === FolderListModel.Null) {
          // Directory doesn't exist or is inaccessible
          root.wallpaperLists[screenName] = []
          root.wallpaperListChanged(screenName, 0)
          QsCommons.Logger.w("Wallpaper", "Directory not accessible for " + screenName + ": " + currentDirectory)
        } else if (status === FolderListModel.Loading) {
          // Flush the list while loading
          root.wallpaperLists[screenName] = []
          scanningCount++
        } else if (status === FolderListModel.Ready) {
          var files = []
          for (var i = 0; i < count; i++) {
            var directory = root.getMonitorDirectory(screenName)
            var filepath = directory + "/" + get(i, "fileName")
            files.push(filepath)
          }

          // Update the list
          root.wallpaperLists[screenName] = files

          scanningCount--
          QsCommons.Logger.d("Wallpaper", "List refreshed for " + screenName + ": " + files.length + " wallpapers")
          root.wallpaperListChanged(screenName, files.length)
        }
      }
    }
  }
}

