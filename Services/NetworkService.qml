pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: root

    // ===== Public Properties =====
    property bool isEnabled: false              // WiFi enabled
    property bool isConnected: false            // Connected to network
    property string ssid: ""                    // Connected network SSID
    property int signalStrength: 0              // Signal strength (0-100)
    property string status: "disconnected"      // Connection status
    property bool initialized: false

    // ===== Private Properties =====
    property bool _isAvailable: false           // NetworkManager available

    // ===== Signals =====
    signal networkChanged()

    // ===== Initialization =====
    function init() {
        if (initialized) {
            Logger.warn("NetworkService", "Already initialized");
            return;
        }

        Logger.log("NetworkService", "Initializing...");
        checkAvailability();
        initialized = true;
        // Note: "Initialization complete" logged after availability check
    }

    // ===== Availability Check =====
    function checkAvailability() {
        try {
            availabilityCheckProcess.running = true;
        } catch (e) {
            Logger.error("NetworkService", "Failed to check availability:", e);
            Logger.callStack();
            _isAvailable = false;
        }
    }

    Process {
        id: availabilityCheckProcess
        running: false
        command: ["sh", "-c", "which nmcli >/dev/null 2>&1 && echo 'available' || echo 'not available'"]

        stdout: StdioCollector {
            onStreamFinished: {
                root._isAvailable = (text.trim() === "available");

                if (!root._isAvailable) {
                    Logger.warn("NetworkService", "NetworkManager (nmcli) not found");
                    return;
                }

                Logger.log("NetworkService", "NetworkManager detected, starting monitoring");
                updateWifiState();
                updateTimer.start();
            }
        }
    }

    // ===== WiFi State Update =====
    function updateWifiState() {
        if (!_isAvailable) return;
        wifiStateProcess.running = true;
    }

    Process {
        id: wifiStateProcess
        running: false
        command: ["nmcli", "radio", "wifi"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    handleWifiStateChange(text.trim() === "enabled");
                } catch (e) {
                    Logger.error("NetworkService", "Failed to parse WiFi state:", e);
                    Logger.callStack();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    Logger.error("NetworkService", "WiFi state check error:", text.trim());
                }
            }
        }
    }

    function handleWifiStateChange(enabled) {
        const wasEnabled = root.isEnabled;
        root.isEnabled = enabled;

        if (wasEnabled !== enabled) {
            Logger.log("NetworkService", "WiFi state changed:", enabled ? "enabled" : "disabled");
            networkChanged();
        }

        if (enabled) {
            updateConnectionStatus();
            return;
        }

        // WiFi disabled - clear connection info
        clearConnectionInfo("disabled");
    }

    function clearConnectionInfo(newStatus) {
        root.isConnected = false;
        root.ssid = "";
        root.signalStrength = 0;
        root.status = newStatus;
        networkChanged();
    }

    // ===== Connection Status Update =====
    function updateConnectionStatus() {
        if (!_isAvailable || !isEnabled) return;
        connectionStatusProcess.running = true;
    }

    Process {
        id: connectionStatusProcess
        running: false
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "device", "wifi", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    parseConnectionStatus(text);
                } catch (e) {
                    Logger.error("NetworkService", "Failed to parse connection status:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    Logger.error("NetworkService", "Connection status check error:", text.trim());
                }
            }
        }
    }

    function parseConnectionStatus(output) {
        const lines = output.split("\n").filter(line => line.trim());
        const activeConnection = findActiveConnection(lines);

        if (!activeConnection) {
            handleDisconnection();
            return;
        }

        handleConnection(activeConnection);
    }

    function findActiveConnection(lines) {
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split(":");

            // Validate format: ACTIVE:SSID:SIGNAL
            if (parts.length < 3) continue;
            if (parts[0] !== "yes") continue;

            return {
                ssid: parts[1],
                signal: parseInt(parts[2]) || 0
            };
        }
        return null;
    }

    function handleConnection(connection) {
        const wasConnected = root.isConnected;
        const wasSsid = root.ssid;
        const wasSignal = root.signalStrength;

        root.isConnected = true;
        root.ssid = connection.ssid;
        root.signalStrength = connection.signal;
        root.status = "connected";

        logConnectionChange(wasConnected, wasSsid, connection.ssid, wasSignal, connection.signal);
        networkChanged();
    }

    function logConnectionChange(wasConnected, wasSsid, newSsid, wasSignal, newSignal) {
        // New connection or SSID changed
        if (!wasConnected || wasSsid !== newSsid) {
            Logger.log("NetworkService", "Connected to:", newSsid, "Signal:", newSignal + "%");
            return;
        }

        // Log significant signal changes (>10%)
        if (Math.abs(wasSignal - newSignal) > 10) {
            Logger.log("NetworkService", "Signal strength changed:", newSignal + "%");
        }
    }

    function handleDisconnection() {
        if (!root.isConnected) return;

        Logger.log("NetworkService", "Disconnected from network");
        clearConnectionInfo("disconnected");
    }

    // ===== Auto-update Timer =====
    Timer {
        id: updateTimer
        interval: Settings.data.network?.updateInterval ?? 30000
        running: false
        repeat: true
        onTriggered: updateWifiState()
    }

    // ===== Helper Functions =====

    // Get icon based on WiFi state and signal strength
    function getIcon() {
        if (!isEnabled) return "󰤮";  // wifi-off
        if (!isConnected) return "󰤯";  // wifi-disconnected

        // Signal strength icons (Nerd Font symbols)
        if (signalStrength >= 80) return "󰤨";  // wifi-strength-4
        if (signalStrength >= 60) return "󰤥";  // wifi-strength-3
        if (signalStrength >= 40) return "󰤢";  // wifi-strength-2
        if (signalStrength >= 20) return "󰤟";  // wifi-strength-1
        return "󰤯";  // wifi-strength-0
    }

    // Get color based on state (using Settings colors)
    function getColor() {
        if (!isEnabled) return Color.mOutlineVariant;
        if (!isConnected) return Color.mError;

        // Signal strength color
        if (signalStrength >= 60) return Color.mPrimary;    // Good signal
        if (signalStrength >= 30) return Color.mTertiary;   // Medium signal
        return Color.mSecondary;  // Low signal = caution
    }

    // Get status text for display
    function getStatusText() {
        if (!isEnabled) return "WiFi Disabled";
        if (!isConnected) return "Not Connected";
        return ssid;
    }
}