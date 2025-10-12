pragma Singleton

import QtQuick
import Quickshell
import "../Commons"

Singleton {
    id: root

    // ===== Panel Management =====
    property var registeredPanels: ({})      // All registered panels by objectName
    property var openedPanel: null           // Currently open panel
    property bool hasOpenedPanel: false      // Quick check if any panel is open

    // ===== Popup Management (for future use) =====
    property var openedPopups: []            // Stack of opened popups
    property bool hasOpenedPopup: false      // Quick check if any popup is open

    // ===== Signals =====
    signal willOpen()                        // Emitted when a panel is about to open
    signal willClose()                       // Emitted when a panel is about to close
    signal popupChanged()                    // Emitted when popup state changes

    // ===== Initialization =====
    Component.onCompleted: {
        Logger.log("PanelService", "Initialized");
    }

    // ===== Panel Registration =====

    /**
     * Register a panel for management
     * @param panel - Panel object to register
     */
    function registerPanel(panel) {
        if (!panel.objectName) {
            Logger.warn("PanelService", "Panel registered without objectName");
            return;
        }

        registeredPanels[panel.objectName] = panel;
        Logger.log("PanelService", "Registered panel:", panel.objectName);
    }

    /**
     * Get a registered panel by name
     * @param name - Panel objectName
     * @return Panel object or null
     */
    function getPanel(name) {
        return registeredPanels[name] || null;
    }

    /**
     * Check if a panel exists
     * @param name - Panel objectName
     * @return true if panel is registered
     */
    function hasPanel(name) {
        return name in registeredPanels;
    }

    // ===== Panel Lifecycle =====

    /**
     * Called when a panel is about to open
     * Enforces single-panel-at-a-time by closing others
     * @param panel - Panel that is opening
     */
    function willOpenPanel(panel) {
        // Close currently open panel if different
        if (openedPanel && openedPanel !== panel) {
            Logger.log("PanelService", "Closing", openedPanel.objectName, "to open", panel.objectName);
            openedPanel.close();
        }

        openedPanel = panel;
        hasOpenedPanel = true;
        willOpen();
    }

    /**
     * Called when a panel is about to close
     * @param panel - Panel that is closing
     */
    function willClosePanel(panel) {
        hasOpenedPanel = false;
        willClose();
    }

    /**
     * Called when a panel has finished closing
     * @param panel - Panel that closed
     */
    function closedPanel(panel) {
        if (openedPanel === panel) {
            openedPanel = null;
        }
    }

    // ===== Popup Management (for future use) =====

    /**
     * Called when a popup is about to open
     * @param popup - Popup object
     */
    function willOpenPopup(popup) {
        openedPopups.push(popup);
        hasOpenedPopup = (openedPopups.length !== 0);
        popupChanged();
    }

    /**
     * Called when a popup is about to close
     * @param popup - Popup object
     */
    function willClosePopup(popup) {
        openedPopups = openedPopups.filter(p => p !== popup);
        hasOpenedPopup = (openedPopups.length !== 0);
        popupChanged();
    }

    // ===== Helper Functions =====

    /**
     * Close all open panels
     */
    function closeAllPanels() {
        if (openedPanel) {
            Logger.log("PanelService", "Closing all panels");
            openedPanel.close();
        }
    }

    /**
     * Close all open popups
     */
    function closeAllPopups() {
        if (hasOpenedPopup) {
            Logger.log("PanelService", "Closing all popups");
            // Close in reverse order (LIFO)
            for (let i = openedPopups.length - 1; i >= 0; i--) {
                if (openedPopups[i] && openedPopups[i].close) {
                    openedPopups[i].close();
                }
            }
        }
    }

    /**
     * Get list of all registered panel names
     * @return Array of panel objectNames
     */
    function getPanelNames() {
        return Object.keys(registeredPanels);
    }

    /**
     * Get count of registered panels
     * @return Number of panels
     */
    function getPanelCount() {
        return Object.keys(registeredPanels).length;
    }
}