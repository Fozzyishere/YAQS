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

    // ===== Private state =====
    property bool initialized: false

    // ===== Initialization =====
    function init() {
        if (initialized) {
            Logger.warn("PanelService", "Already initialized");
            return;
        }

        Logger.log("PanelService", "Initializing...");
        // PanelService is passive - panels register themselves
        initialized = true;
        Logger.log("PanelService", "Initialization complete");
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

    /**
     * Open a panel on a specific screen
     * @param panel - Panel object (or panel name string)
     * @param screen - ShellScreen to open on
     * @param buttonItem - Optional button widget for positioning
     */
    function openPanelOnScreen(panel, screen, buttonItem) {
        // Allow passing panel name or panel object
        const panelObj = typeof panel === 'string' ? getPanel(panel) : panel;

        if (!panelObj) {
            Logger.warn("PanelService", "Panel not found:", panel);
            return;
        }

        // Set the screen before opening
        if (screen) {
            panelObj.screen = screen;
            Logger.log("PanelService", "Opening", panelObj.objectName, "on screen", screen.name);
        } else {
            // Fallback to first screen if no screen provided
            panelObj.screen = Quickshell.screens[0] || null;
            Logger.warn("PanelService", "No screen provided, using first screen");
        }

        // Open the panel with optional button positioning
        if (buttonItem !== undefined && buttonItem !== null) {
            panelObj.open(buttonItem);
        } else {
            panelObj.open();
        }
    }

    /**
     * Helper: Get screen from a widget by traversing parent hierarchy
     * @param widget - Widget to find screen for
     * @return ShellScreen or null
     */
    function getScreenFromWidget(widget) {
        if (!widget) return null;

        // Try to find screen in widget's parent hierarchy
        let current = widget;
        while (current) {
            if (current.screen) {
                Logger.log("PanelService", "Found screen:", current.screen.name);
                return current.screen;
            }
            current = current.parent;
        }

        // Fallback to first screen
        Logger.warn("PanelService", "Could not find screen in widget hierarchy, using first screen");
        return Quickshell.screens[0] || null;
    }

    /**
     * Convenience: Open panel on widget's screen (auto-detect)
     * @param panel - Panel object or name
     * @param buttonItem - Widget that triggered the panel (will auto-detect screen)
     */
    function openPanelFromWidget(panel, buttonItem) {
        const screen = getScreenFromWidget(buttonItem);
        openPanelOnScreen(panel, screen, buttonItem);
    }
}