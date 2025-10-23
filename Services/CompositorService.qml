pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

Singleton {
    id: root

    // ===== Compositor detection =====
    property bool isHyprland: false
    property bool isNiri: false
    property bool initialized: false

    // ===== Facade properties (synced from backend) =====
    property ListModel workspaces: ListModel {}
    property var windows: []
    property int focusedWindowIndex: -1

    // ===== Signals =====
    signal workspaceChanged
    signal activeWindowChanged
    signal windowListChanged
    // Note: workspacesChanged is auto-generated from 'property ListModel workspaces'

    // ===== Backend reference =====
    property var backend: null

    // ===== Initialization =====
    function init() {
        if (initialized) {
            Logger.warn("CompositorService", "Already initialized");
            return;
        }

        Logger.log("CompositorService", "Initializing...");
        detectCompositor();
        initialized = true;
        // Note: "Initialization complete" logged after compositor detection
    }

    // ===== Compositor detection =====
    function detectCompositor() {
        const hyprlandSignature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE");
        if (hyprlandSignature && hyprlandSignature.length > 0) {
            isHyprland = true;
            isNiri = false;
            backendLoader.sourceComponent = hyprlandComponent;
            Logger.log("CompositorService", "Detected Hyprland");
        } else {
            // Future: Add Niri support
            Logger.warn("CompositorService", "No supported compositor detected (expected Hyprland)");
        }
    }

    // ===== Backend loader (lazy instantiation) =====
    Loader {
        id: backendLoader
        onLoaded: {
            if (item) {
                root.backend = item;
                setupBackendConnections();
                backend.init();  // Initialize backend service
                Logger.log("CompositorService", "Backend initialized");
            }
        }
    }

    // ===== Backend components =====
    Component {
        id: hyprlandComponent
        HyprlandService {
            id: hyprlandBackend
        }
    }

    // ===== Setup backend connections =====
    function setupBackendConnections() {
        if (!backend)
            return;

        // Connect backend signals to facade signals
        backend.workspaceChanged.connect(() => {
            syncWorkspaces();
            workspaceChanged();
        });

        backend.activeWindowChanged.connect(() => {
            syncWindows();
            activeWindowChanged();
        });

        backend.windowListChanged.connect(() => {
            syncWindows();
            windowListChanged();
        });

        // Property bindings
        backend.focusedWindowIndexChanged.connect(() => {
            focusedWindowIndex = backend.focusedWindowIndex;
        });

        // Initial sync
        syncWorkspaces();
        syncWindows();
        focusedWindowIndex = backend.focusedWindowIndex;
    }

    // ===== Sync backend ListModel to facade ListModel =====
    function syncWorkspaces() {
        workspaces.clear();
        if (!backend || !backend.workspaces)
            return;
        for (var i = 0; i < backend.workspaces.count; i++) {
            workspaces.append(backend.workspaces.get(i));
        }
    }

    function syncWindows() {
        if (!backend) {
            windows = [];
            return;
        }
        windows = backend.windows;
    }

    // ===== Helper methods =====

    // Get focused window
    function getFocusedWindow() {
        if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.length) {
            return windows[focusedWindowIndex];
        }
        return null;
    }

    // Get focused window title
    function getFocusedWindowTitle() {
        const focusedWindow = getFocusedWindow();
        return focusedWindow ? (focusedWindow.title || "") : "";
    }

    // Get current workspace (focused)
    function getCurrentWorkspace() {
        for (var i = 0; i < workspaces.count; i++) {
            const ws = workspaces.get(i);
            if (ws.isFocused) {
                return ws;
            }
        }
        return null;
    }

    // Get active workspaces (per monitor)
    function getActiveWorkspaces() {
        const activeWorkspaces = [];
        for (var i = 0; i < workspaces.count; i++) {
            const ws = workspaces.get(i);
            if (ws.isActive) {
                activeWorkspaces.push(ws);
            }
        }
        return activeWorkspaces;
    }

    // ===== Public API =====

    function switchToWorkspace(workspaceId) {
        if (backend && backend.switchToWorkspace) {
            backend.switchToWorkspace(workspaceId);
        } else {
            Logger.warn("CompositorService", "No backend available for workspace switching");
        }
    }

    function focusWindow(windowId) {
        if (backend && backend.focusWindow) {
            backend.focusWindow(windowId);
        } else {
            Logger.warn("CompositorService", "No backend available for window focus");
        }
    }

    function closeWindow(windowId) {
        if (backend && backend.closeWindow) {
            backend.closeWindow(windowId);
        } else {
            Logger.warn("CompositorService", "No backend available for window closing");
        }
    }

    // ===== Session management =====

    function logout() {
        if (backend && backend.logout) {
            backend.logout();
        } else {
            Logger.warn("CompositorService", "No backend available for logout");
        }
    }

    function shutdown() {
        try {
            Quickshell.execDetached(["shutdown", "-h", "now"]);
        } catch (e) {
            Logger.error("CompositorService", "Failed to shutdown:", e);
        }
    }

    function reboot() {
        try {
            Quickshell.execDetached(["reboot"]);
        } catch (e) {
            Logger.error("CompositorService", "Failed to reboot:", e);
        }
    }

    function suspend() {
        try {
            Quickshell.execDetached(["systemctl", "suspend"]);
        } catch (e) {
            Logger.error("CompositorService", "Failed to suspend:", e);
        }
    }
}
