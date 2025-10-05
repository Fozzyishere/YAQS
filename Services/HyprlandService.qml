import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Commons"

Item {
  id: root

  // ===== Properties =====
  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1

  // ===== Signals =====
  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged

  // ===== Internal state =====
  property bool initialized: false
  property var workspaceCache: ({})
  property var windowCache: ({})

  // ===== Debounce timer =====
  Timer {
    id: updateTimer
    interval: 50
    repeat: false
    onTriggered: safeUpdate()
  }

  // ===== Initialization (called by CompositorService) =====
  function initialize() {
    if (initialized) return

    try {
      Hyprland.refreshWorkspaces()
      Hyprland.refreshToplevels()
      Qt.callLater(() => {
        safeUpdateWorkspaces()
        safeUpdateWindows()
      })
      initialized = true
      Logger.log("HyprlandService", "Initialized successfully")
    } catch (e) {
      Logger.error("HyprlandService", "Failed to initialize:", e)
    }
  }

  // ===== Update wrapper =====
  function safeUpdate() {
    safeUpdateWindows()
    safeUpdateWorkspaces()
    windowListChanged()
  }

  // ===== Workspace update =====
  function safeUpdateWorkspaces() {
    try {
      workspaces.clear()
      workspaceCache = {}

      if (!Hyprland.workspaces || !Hyprland.workspaces.values) {
        return  // Graceful degradation 
      }

      const hlWorkspaces = Hyprland.workspaces.values
      const occupiedIds = getOccupiedWorkspaceIds()

      for (var i = 0; i < hlWorkspaces.length; i++) {
        const ws = hlWorkspaces[i]
        if (!ws || ws.id < 1) continue  // Skip invalid workspaces

        const wsData = {
          "id": i,                                                // Array index
          "idx": ws.id,                                           // Hyprland workspace ID
          "name": ws.name || "",                                  // Workspace name
          "output": (ws.monitor && ws.monitor.name) ? ws.monitor.name : "",  // Monitor name (critical for per-monitor filtering!)
          "isActive": ws.active === true,                         // Active on this monitor
          "isFocused": ws.focused === true,                       // Currently focused
          "isUrgent": ws.urgent === true,                         // Has urgent window
          "isOccupied": occupiedIds[ws.id] === true               // Has windows (boolean)
        }

        workspaceCache[ws.id] = wsData  // Cache for fast lookups
        workspaces.append(wsData)       // Add to ListModel
      }
    } catch (e) {
      Logger.error("HyprlandService", "Error updating workspaces:", e)
    }
  }

  // ===== Get occupied workspace IDs =====
  function getOccupiedWorkspaceIds() {
    const occupiedIds = {}

    try {
      if (!Hyprland.toplevels || !Hyprland.toplevels.values) {
        return occupiedIds
      }

      const hlToplevels = Hyprland.toplevels.values
      for (var i = 0; i < hlToplevels.length; i++) {
        const toplevel = hlToplevels[i]
        if (!toplevel) continue

        try {
          const wsId = toplevel.workspace ? toplevel.workspace.id : null
          if (wsId !== null && wsId !== undefined) {
            occupiedIds[wsId] = true  // Just mark as occupied (boolean)
          }
        } catch (e) {
          // Ignore individual toplevel errors
        }
      }
    } catch (e) {
      // Return empty if we can't determine occupancy
    }

    return occupiedIds
  }

  // ===== Window update =====
  function safeUpdateWindows() {
    try {
      const windowsList = []
      windowCache = {}

      if (!Hyprland.toplevels || !Hyprland.toplevels.values) {
        windows = []
        focusedWindowIndex = -1
        return
      }

      const hlToplevels = Hyprland.toplevels.values
      let newFocusedIndex = -1

      for (var i = 0; i < hlToplevels.length; i++) {
        const toplevel = hlToplevels[i]
        if (!toplevel) continue

        const windowData = extractWindowData(toplevel)
        if (windowData) {
          windowsList.push(windowData)
          windowCache[windowData.id] = windowData

          if (windowData.isFocused) {
            newFocusedIndex = windowsList.length - 1
          }
        }
      }

      windows = windowsList

      if (newFocusedIndex !== focusedWindowIndex) {
        focusedWindowIndex = newFocusedIndex
        activeWindowChanged()
      }
    } catch (e) {
      Logger.error("HyprlandService", "Error updating windows:", e)
    }
  }

  // ===== Extract window data =====
  function extractWindowData(toplevel) {
    if (!toplevel) return null

    try {
      const windowId = safeGetProperty(toplevel, "address", "")
      if (!windowId) return null

      const appId = extractAppId(toplevel)
      const title = safeGetProperty(toplevel, "title", "")
      const wsId = toplevel.workspace ? toplevel.workspace.id : null
      const focused = toplevel.activated === true

      return {
        "id": windowId,
        "title": title,
        "appId": appId,
        "workspaceId": wsId,
        "isFocused": focused
      }
    } catch (e) {
      return null
    }
  }

  // ===== Extract app ID from various sources =====
  function extractAppId(toplevel) {
    if (!toplevel) return ""

    // Try different properties that might contain the app ID
    var appId = safeGetProperty(toplevel, "class", "")
    if (appId) return appId

    appId = safeGetProperty(toplevel, "initialClass", "")
    if (appId) return appId

    appId = safeGetProperty(toplevel, "appId", "")
    if (appId) return appId

    return ""
  }

  // ===== Getter =====
  function safeGetProperty(obj, prop, defaultValue) {
    try {
      const value = obj[prop]
      if (value !== undefined && value !== null) {
        return String(value)
      }
    } catch (e) {
      // Property access failed
    }
    return defaultValue
  }

  // ===== Connections to Hyprland =====
  Connections {
    target: Hyprland.workspaces
    enabled: initialized
    function onValuesChanged() {
      safeUpdateWorkspaces()
      workspaceChanged()
    }
  }

  Connections {
    target: Hyprland.toplevels
    enabled: initialized
    function onValuesChanged() {
      updateTimer.restart()  // Debounced window updates
    }
  }

  Connections {
    target: Hyprland
    enabled: initialized
    function onRawEvent(event) {
      safeUpdateWorkspaces()
      workspaceChanged()
      updateTimer.restart()
    }
  }

  // ===== Public API =====
  function switchToWorkspace(workspaceId) {
    try {
      Hyprland.dispatch(`workspace ${workspaceId}`)
    } catch (e) {
      Logger.error("HyprlandService", "Failed to switch workspace:", e)
    }
  }

  function focusWindow(windowId) {
    try {
      Hyprland.dispatch(`focuswindow address:${windowId}`)
    } catch (e) {
      Logger.error("HyprlandService", "Failed to focus window:", e)
    }
  }

  function closeWindow(windowId) {
    try {
      Hyprland.dispatch(`closewindow address:${windowId}`)
    } catch (e) {
      Logger.error("HyprlandService", "Failed to close window:", e)
    }
  }

  function logout() {
    try {
      Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
    } catch (e) {
      Logger.error("HyprlandService", "Failed to logout:", e)
    }
  }
}