pragma Singleton

import Quickshell
import "../Commons" as QsCommons

Singleton {
  id: root

  // Lock screen doesn't participate in single-open enforcement
  property var lockScreen: null

  // Panels register themselves on creation using registerPanel()
  property var registeredPanels: ({})

  // Currently opened panel
  property var openedPanel: null

  // Currently opened popups (can have multiple)
  property var openedPopups: []
  property bool hasOpenedPopup: false

  // Signals
  signal willOpen    // Emitted when a panel is about to open
  signal popupChanged  // Emitted when popup stack changes

  // === Panel Management ===

  // Register a panel in the registry
  function registerPanel(panel) {
    if (!panel || !panel.objectName) {
      QsCommons.Logger.w("PanelService", "Cannot register panel without objectName")
      return
    }

    registeredPanels[panel.objectName] = panel
    QsCommons.Logger.d("PanelService", "Registered:", panel.objectName)
  }

  // Get a panel by objectName
  function getPanel(name) {
    return registeredPanels[name] || null
  }

  // Check if a panel exists in registry
  function hasPanel(name) {
    return name in registeredPanels
  }

  // Called when a panel is about to open
  function willOpenPanel(panel) {
    // Close currently opened panel if it's different
    if (openedPanel && openedPanel !== panel) {
      openedPanel.close()
    }

    // Track new opened panel
    openedPanel = panel

    // Emit signal (for Bar highlight, etc.)
    willOpen()
  }

  // Called when a panel closes
  function closedPanel(panel) {
    // Clear opened panel if it matches
    if (openedPanel && openedPanel === panel) {
      openedPanel = null
    }
  }

  // === Popup Management ===

  // Called when a popup opens
  function willOpenPopup(popup) {
    openedPopups.push(popup)
    hasOpenedPopup = (openedPopups.length !== 0)
    popupChanged()
  }

  // Called when a popup closes
  function willClosePopup(popup) {
    openedPopups = openedPopups.filter(p => p !== popup)
    hasOpenedPopup = (openedPopups.length !== 0)
    popupChanged()
  }
}
