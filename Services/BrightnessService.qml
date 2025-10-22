pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons"

Singleton {
    id: root

    // ===== Public Properties =====
    property int brightness: 50                 // Current brightness (0-100)
    property int maxBrightness: 100             // Maximum brightness value
    property bool isAvailable: false            // Brightness control available

    // ===== Private Properties =====
    property string _backend: ""                // brightnessctl or light
    property string _backlightDevice: ""        // /sys/class/backlight/...
    property string _brightnessPath: ""         // brightness file path
    property string _maxBrightnessPath: ""      // max_brightness file path
    property bool _isPolling: false             // Polling active
    property int _queuedBrightness: -1          // Debounced value (-1 = none)


    // ===== Initialization =====
    Component.onCompleted: {
        Logger.log("BrightnessService", "Initialized");
        detectBackend();
    }

    // ===== Backend Detection =====
    function detectBackend() {
        // Try brightnessctl first
        brightnessctlCheckProcess.running = true;
    }

    Process {
        id: brightnessctlCheckProcess
        running: false
        command: ["sh", "-c", "which brightnessctl >/dev/null 2>&1 && echo 'found' || echo 'not found'"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "found") {
                    root._backend = "brightnessctl";
                    root.isAvailable = true;
                    Logger.log("BrightnessService", "Using backend: brightnessctl");
                    initBrightness();
                    startPolling();
                    return;
                }

                // Try light as fallback
                lightCheckProcess.running = true;
            }
        }
    }

    Process {
        id: lightCheckProcess
        running: false
        command: ["sh", "-c", "which light >/dev/null 2>&1 && echo 'found' || echo 'not found'"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "found") {
                    root._backend = "light";
                    root.isAvailable = true;
                    Logger.log("BrightnessService", "Using backend: light");
                    initBrightness();
                    startPolling();
                    return;
                }

                Logger.warn("BrightnessService", "No brightness control tool found (tried: brightnessctl, light)");
                root.isAvailable = false;
            }
        }
    }

    // ===== Initialize Brightness =====
    function initBrightness() {
        if (!isAvailable) return;

        if (_backend === "brightnessctl") {
            initBrightnessctlProcess.running = true;
        } else if (_backend === "light") {
            initLightProcess.running = true;
        }
    }

    // Brightnessctl: get device path, current, and max brightness
    Process {
        id: initBrightnessctlProcess
        running: false
        command: ["sh", "-c", `
            # Get device path
            device=$(brightnessctl --list | grep -o 'Device.*backlight' | head -1 | awk '{print "/sys/class/backlight/" $2}' | tr -d "'")
            if [ -z "$device" ]; then
                # Fallback: find first backlight device
                device=$(find /sys/class/backlight -maxdepth 1 -type d | grep -v "^/sys/class/backlight$" | head -1)
            fi

            # Get current and max brightness
            current=$(brightnessctl get)
            max=$(brightnessctl max)

            echo "$device"
            echo "$current"
            echo "$max"
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length < 3) {
                    Logger.error("BrightnessService", "Failed to get brightness info");
                    return;
                }

                handleBrightnessInit(lines[0], parseInt(lines[1]), parseInt(lines[2]));
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    Logger.error("BrightnessService", "brightnessctl init error:", text.trim());
                }
            }
        }
    }

    // Light: get current brightness directly (returns percentage)
    Process {
        id: initLightProcess
        running: false
        command: ["light", "-G"]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseFloat(text.trim());
                if (isNaN(value)) {
                    Logger.error("BrightnessService", "Failed to parse light output");
                    return;
                }

                root.brightness = Math.round(value);
                root.maxBrightness = 100;  // light always uses percentage
                Logger.log("BrightnessService", "Initial brightness:", root.brightness + "%");
                brightnessChanged();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    Logger.error("BrightnessService", "light init error:", text.trim());
                }
            }
        }
    }

    function handleBrightnessInit(devicePath, current, max) {
        if (!devicePath || isNaN(current) || isNaN(max) || max === 0) {
            Logger.error("BrightnessService", "Invalid brightness data");
            return;
        }

        root._backlightDevice = devicePath;
        root._brightnessPath = devicePath + "/brightness";
        root._maxBrightnessPath = devicePath + "/max_brightness";
        root.maxBrightness = max;
        root.brightness = Math.round((current / max) * 100);

        Logger.log("BrightnessService", "Using backlight device:", devicePath);
        Logger.log("BrightnessService", "Initial brightness:", current + "/" + max, "=", root.brightness + "%");

        // Start file watching
        brightnessWatcher.path = root._brightnessPath;

        brightnessChanged();
    }

    // ===== File Watcher (for hardware key detection) =====
    FileView {
        id: brightnessWatcher
        path: ""  // Set when backend detected
        watchChanges: true

        onFileChanged: {
            // Hardware brightness key pressed - update our value
            if (_backend === "brightnessctl") {
                updateBrightnessFromSystem();
            }
        }
    }

    // ===== Polling Timer (for hardware key detection) =====
    function startPolling() {
        if (_backend === "light") {
            // light doesn't have file watching, use polling
            _isPolling = true;
            pollTimer.start();
        }
    }

    Timer {
        id: pollTimer
        interval: Settings.data.brightness?.pollInterval ?? 500
        running: false
        repeat: true

        onTriggered: {
            if (root._isPolling && root._backend === "light") {
                updateBrightnessFromSystem();
            }
        }
    }

    // ===== Update from System (detect hardware changes) =====
    function updateBrightnessFromSystem() {
        if (!isAvailable) return;

        if (_backend === "brightnessctl") {
            updateBrightnessctlProcess.running = true;
        } else if (_backend === "light") {
            updateLightProcess.running = true;
        }
    }

    Process {
        id: updateBrightnessctlProcess
        running: false
        command: ["brightnessctl", "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                const current = parseInt(text.trim());
                if (isNaN(current) || root.maxBrightness === 0) return;

                const newBrightness = Math.round((current / root.maxBrightness) * 100);

                // Only update if changed significantly (avoid noise)
                if (Math.abs(newBrightness - root.brightness) > 1) {
                    root.brightness = newBrightness;
                    brightnessChanged();
                }
            }
        }
    }

    Process {
        id: updateLightProcess
        running: false
        command: ["light", "-G"]

        stdout: StdioCollector {
            onStreamFinished: {
                const newBrightness = Math.round(parseFloat(text.trim()));
                if (isNaN(newBrightness)) return;

                if (Math.abs(newBrightness - root.brightness) > 1) {
                    root.brightness = newBrightness;
                    brightnessChanged();
                }
            }
        }
    }

    // ===== Set Brightness =====
    function setBrightness(percent) {
        if (!isAvailable) return;

        const clamped = Math.max(0, Math.min(100, Math.round(percent)));

        if (_debounceTimer.running) {
            _queuedBrightness = clamped;
            return;
        }

        applyBrightness(clamped);
        _debounceTimer.start();
    }

    function applyBrightness(percent) {
        root.brightness = percent;
        brightnessChanged();

        if (_backend === "brightnessctl") {
            Quickshell.execDetached(["brightnessctl", "set", percent + "%"]);
        } else if (_backend === "light") {
            Quickshell.execDetached(["light", "-S", percent.toString()]);
        }

        Logger.log("BrightnessService", "Set brightness:", percent + "%");
    }

    Timer {
        id: _debounceTimer
        interval: 100
        repeat: false

        onTriggered: {
            if (root._queuedBrightness >= 0) {
                applyBrightness(root._queuedBrightness);
                root._queuedBrightness = -1;
            }
        }
    }

    // ===== Increase/Decrease Methods =====
    function increaseBrightness(step) {
        if (!isAvailable) return;

        const targetStep = step || (Settings.data.brightness?.step ?? 5);
        const targetValue = _queuedBrightness >= 0 ? _queuedBrightness : brightness;
        setBrightness(targetValue + targetStep);
    }

    function decreaseBrightness(step) {
        if (!isAvailable) return;

        const targetStep = step || (Settings.data.brightness?.step ?? 5);
        const targetValue = _queuedBrightness >= 0 ? _queuedBrightness : brightness;
        setBrightness(targetValue - targetStep);
    }

    // ===== Helper Functions =====

    // Get icon based on brightness level
    function getIcon() {
        if (!isAvailable) return "󰃞";  // brightness-alert

        if (brightness >= 80) return "󰃠";  // brightness-high
        if (brightness >= 50) return "󰃟";  // brightness-medium
        if (brightness >= 20) return "󰃝";  // brightness-low
        return "󰃞";  // brightness-minimum
    }

    // Get color based on availability
    function getColor() {
        return isAvailable ? Color.mTertiary : Color.mOutlineVariant;
    }
}
