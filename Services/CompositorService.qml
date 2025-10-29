pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Detection Properties ===
  property bool isHyprland: false
  property bool isNiri: false
  property bool isSway: false

  // === Unified Data ===
  property ListModel workspaces: ListModel {}
  property ListModel windows: ListModel {}
  property int focusedWindowIndex: -1

  // === Display Scales ===
  property var displayScales: ({})
  property bool displayScalesLoaded: false

  // === Cache Path ===
  property string displayCachePath: ""

  // === Backend Reference ===
  property var backend: null

  // === Signals ===
  signal workspaceChanged()
  signal activeWindowChanged()
  signal windowListChanged()
  // Note: displayScales property automatically generates displayScalesChanged() signal

  // === Initialization ===
  Component.onCompleted: {
    // Setup cache path after Settings is available
    Qt.callLater(() => {
      if (typeof QsCommons.Settings !== 'undefined' && QsCommons.Settings.cacheDir) {
        displayCachePath = QsCommons.Settings.cacheDir + "/display.json"
        displayCacheFileView.path = displayCachePath
      }
    })

    detectCompositor()
  }

  // === Compositor Detection ===
  function detectCompositor() {
    const hyprlandSignature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    const niriSocket = Quickshell.env("NIRI_SOCKET")
    const swaySock = Quickshell.env("SWAYSOCK")

    if (hyprlandSignature && hyprlandSignature.length > 0) {
      QsCommons.Logger.i("CompositorService", "Detected Hyprland compositor")
      isHyprland = true
      isNiri = false
      isSway = false
      backendLoader.sourceComponent = hyprlandComponent
    } else if (niriSocket && niriSocket.length > 0) {
      QsCommons.Logger.w("CompositorService", "Detected Niri compositor (not supported, using Hyprland backend)")
      isHyprland = true  // Fake Hyprland for fallback
      isNiri = true
      isSway = false
      backendLoader.sourceComponent = hyprlandComponent
    } else if (swaySock && swaySock.length > 0) {
      QsCommons.Logger.w("CompositorService", "Detected Sway compositor (not supported, using Hyprland backend)")
      isHyprland = true  // Fake Hyprland for fallback
      isNiri = false
      isSway = true
      backendLoader.sourceComponent = hyprlandComponent
    } else {
      QsCommons.Logger.w("CompositorService", "No compositor detected, defaulting to Hyprland backend")
      isHyprland = true
      isNiri = false
      isSway = false
      backendLoader.sourceComponent = hyprlandComponent
    }
  }

  // === Backend Loader ===
  Loader {
    id: backendLoader
    onLoaded: {
      if (item) {
        root.backend = item
        setupBackendConnections()
        backend.initialize()
      }
    }
  }

  // === Backend Components ===
  Component {
    id: hyprlandComponent
    HyprlandService {
      id: hyprlandBackend
    }
  }

  // === Display Cache FileView ===
  FileView {
    id: displayCacheFileView
    printErrors: false
    watchChanges: false

    adapter: JsonAdapter {
      id: displayCacheAdapter
      property var displays: ({})
    }

    onLoaded: {
      displayScales = displayCacheAdapter.displays || {}
      displayScalesLoaded = true
      QsCommons.Logger.d("CompositorService", "Loaded display scales from cache")
    }

    onLoadFailed: {
      displayScalesLoaded = true
      QsCommons.Logger.d("CompositorService", "No display cache found, will create on first update")
    }
  }

  // === Backend Connection Setup ===
  function setupBackendConnections() {
    if (!backend) return

    // Connect signals
    backend.workspaceChanged.connect(() => {
      syncWorkspaces()
      workspaceChanged()
    })

    backend.activeWindowChanged.connect(() => {
      syncWindows()
      activeWindowChanged()
    })

    backend.windowListChanged.connect(() => {
      syncWindows()
      windowListChanged()
    })

    // Property bindings
    backend.focusedWindowIndexChanged.connect(() => {
      focusedWindowIndex = backend.focusedWindowIndex
    })

    // Initial sync
    syncWorkspaces()
    syncWindows()
    focusedWindowIndex = backend.focusedWindowIndex
  }

  // === Data Synchronization ===
  function syncWorkspaces() {
    workspaces.clear()
    const ws = backend.workspaces
    for (var i = 0; i < ws.count; i++) {
      workspaces.append(ws.get(i))
    }
  }

  function syncWindows() {
    windows.clear()
    const ws = backend.windows
    for (var i = 0; i < ws.length; i++) {
      windows.append(ws[i])
    }
  }

  // === Display Scale Management ===
  function updateDisplayScales() {
    if (!backend || !backend.queryDisplayScales) {
      QsCommons.Logger.w("CompositorService", "Backend does not support display scale queries")
      return
    }
    backend.queryDisplayScales()
  }

  function onDisplayScalesUpdated(scales) {
    displayScales = scales
    saveDisplayScalesToCache()
    // displayScalesChanged() signal is automatically emitted when displayScales changes
    QsCommons.Logger.i("CompositorService", "Display scales updated")
  }

  function saveDisplayScalesToCache() {
    if (!displayCachePath) return

    displayCacheAdapter.displays = displayScales
    displayCacheFileView.writeAdapter()
  }

  function getDisplayScale(displayName) {
    if (!displayName || !displayScales[displayName]) {
      return 1.0
    }
    return displayScales[displayName].scale || 1.0
  }

  function getDisplayInfo(displayName) {
    if (!displayName || !displayScales[displayName]) {
      return null
    }
    return displayScales[displayName]
  }

  // === Workspace Functions ===
  function switchToWorkspace(workspace) {
    if (backend && backend.switchToWorkspace) {
      backend.switchToWorkspace(workspace)
    } else {
      QsCommons.Logger.w("CompositorService", "No backend available for workspace switching")
    }
  }

  function getCurrentWorkspace() {
    for (var i = 0; i < workspaces.count; i++) {
      const ws = workspaces.get(i)
      if (ws.isFocused) {
        return ws
      }
    }
    return null
  }

  function getActiveWorkspaces() {
    const activeWorkspaces = []
    for (var i = 0; i < workspaces.count; i++) {
      const ws = workspaces.get(i)
      if (ws.isActive) {
        activeWorkspaces.push(ws)
      }
    }
    return activeWorkspaces
  }

  // === Window Functions ===
  function getFocusedWindow() {
    if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.count) {
      return windows.get(focusedWindowIndex)
    }
    return null
  }

  function getFocusedWindowTitle() {
    if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.count) {
      var title = windows.get(focusedWindowIndex).title
      if (title !== undefined) {
        title = title.replace(/(\r\n|\n|\r)/g, "")
      }
      return title || ""
    }
    return ""
  }

  function getWindowsForWorkspace(workspaceId) {
    var windowsInWs = []
    for (var i = 0; i < windows.count; i++) {
      var window = windows.get(i)
      if (window.workspaceId === workspaceId) {
        windowsInWs.push(window)
      }
    }
    return windowsInWs
  }

  function focusWindow(window) {
    if (backend && backend.focusWindow) {
      backend.focusWindow(window)
    } else {
      QsCommons.Logger.w("CompositorService", "No backend available for window focus")
    }
  }

  function closeWindow(window) {
    if (backend && backend.closeWindow) {
      backend.closeWindow(window)
    } else {
      QsCommons.Logger.w("CompositorService", "No backend available for window closing")
    }
  }

  // === Session Management ===
  function logout() {
    if (backend && backend.logout) {
      QsCommons.Logger.i("CompositorService", "Logout requested")
      backend.logout()
    } else {
      QsCommons.Logger.w("CompositorService", "No backend available for logout")
    }
  }

  function shutdown() {
    QsCommons.Logger.i("CompositorService", "Shutdown requested")
    Quickshell.execDetached(["systemctl", "poweroff"])
  }

  function reboot() {
    QsCommons.Logger.i("CompositorService", "Reboot requested")
    Quickshell.execDetached(["systemctl", "reboot"])
  }

  function suspend() {
    QsCommons.Logger.i("CompositorService", "Suspend requested")
    Quickshell.execDetached(["systemctl", "suspend"])
  }

  function lockAndSuspend() {
    QsCommons.Logger.i("CompositorService", "Lock and suspend requested")
    // Note: PanelService and LockScreen not implemented yet. Uncomment when available.
    // try {
    //   if (PanelService && PanelService.lockScreen && !PanelService.lockScreen.active) {
    //     PanelService.lockScreen.active = true
    //   }
    // } catch (e) {
    //   QsCommons.Logger.w("CompositorService", "Failed to activate lock screen: " + e)
    // }
    Qt.callLater(suspend)
  }
}
