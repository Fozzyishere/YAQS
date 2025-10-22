pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../Commons"

Singleton {
    id: root

    // ===== Properties =====
    property bool hasBattery: false         // Battery device exists
    property int batteryPercent: 0          // Percentage (0-100)
    property bool isCharging: false         // Currently charging
    property bool isReady: false            // Device ready

    // ===== Signal =====
    signal batteryChanged()

    // ===== Private state =====
    property var batteryDevice: null

    // ===== Initialization =====
    Component.onCompleted: {
        Logger.log("BatteryService", "Initialized");
        updateBattery();
    }


    // ===== Watch for battery property changes =====
    Connections {
        target: root.batteryDevice
        enabled: root.batteryDevice !== null

        function onPercentageChanged() {
            root.safeUpdateBattery();
        }

        function onStateChanged() {
            root.safeUpdateBattery();
        }

        function onReadyChanged() {
            root.safeUpdateBattery();
        }

        function onIsPresentChanged() {
            root.safeUpdateBattery();
        }
    }

    // ===== Update battery state =====
    function updateBattery() {
        try {
            const device = UPower.displayDevice;

            if (!device) {
                // No display device
                hasBattery = false;
                batteryDevice = null;
                isReady = false;
                batteryPercent = 0;
                isCharging = false;
                Logger.log("BatteryService", "No display device found");
                return;
            }

            batteryDevice = device;
            safeUpdateBattery();
        } catch (e) {
            Logger.error("BatteryService", "Failed to update battery:", e);
            hasBattery = false;
            isReady = false;
        }
    }

    // ===== Safe battery update (from existing device) =====
    function safeUpdateBattery() {
        if (!batteryDevice) {
            hasBattery = false;
            isReady = false;
            batteryPercent = 0;
            isCharging = false;
            batteryChanged();
            return;
        }

        try {
            // Check if device is ready and present
            const ready = safeGetProperty(batteryDevice, "ready", false);
            const present = safeGetProperty(batteryDevice, "isPresent", false);
            const isLaptopBatt = safeGetProperty(batteryDevice, "isLaptopBattery", false);

            // Only show if it's a laptop battery
            if (!ready || !present || !isLaptopBatt) {
                hasBattery = false;
                isReady = false;
                batteryPercent = 0;
                isCharging = false;
                batteryChanged();
                return;
            }

            // Get battery properties
            isReady = true;
            hasBattery = true;

            const percentage = safeGetProperty(batteryDevice, "percentage", 0);
            batteryPercent = Math.round(percentage * 100);

            const state = batteryDevice.state;
            isCharging = (state === 1 || state === UPowerDeviceState.Charging);

            batteryChanged();

            Logger.log("BatteryService", 
                      `Battery: ${batteryPercent}%, charging=${isCharging}, ready=${isReady}`);
        } catch (e) {
            Logger.error("BatteryService", "Failed to read battery properties:", e);
            hasBattery = false;
            isReady = false;
        }
    }

    // ===== Safe property getter =====
    function safeGetProperty(obj, prop, defaultValue) {
        try {
            const value = obj[prop];
            if (value !== undefined && value !== null) {
                return value;
            }
        } catch (e) {
            // Property access failed
        }
        return defaultValue;
    }

    // ===== Helper: Get icon based on state =====
    function getIcon() {
        if (!hasBattery || !isReady) {
            return "󰂑";  // battery-outline (Nerd Font)
        }

        if (isCharging) {
            return "󰂄";  // battery-charging (Nerd Font)
        }

        // Icon based on charge level
        if (batteryPercent >= 90) return "󰁹";  // battery-90
        if (batteryPercent >= 80) return "󰂂";  // battery-80
        if (batteryPercent >= 70) return "󰂁";  // battery-70
        if (batteryPercent >= 60) return "󰂀";  // battery-60
        if (batteryPercent >= 50) return "󰁿";  // battery-50
        if (batteryPercent >= 40) return "󰁾";  // battery-40
        if (batteryPercent >= 30) return "󰁽";  // battery-30
        if (batteryPercent >= 20) return "󰁼";  // battery-20
        if (batteryPercent >= 10) return "󰁻";  // battery-10
        return "󰁺";  // battery-alert (< 10%)
    }

    // ===== Helper: Get color based on state =====
    function getColor() {
        if (!hasBattery || !isReady) {
            return Color.mOutlineVariant;
        }

        if (isCharging) {
            return Color.mSuccess;  // Charging = green
        }

        // Color based on charge level
        if (batteryPercent < 10) return Color.mError;    // Critical = red
        if (batteryPercent < 20) return Color.mError;    // Low = red
        if (batteryPercent < 40) return Color.mTertiary;    // Medium = yellow
        return Color.mOnSurface;  // Normal = default foreground
    }
}
