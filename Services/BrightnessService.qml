pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Properties ===
  readonly property list<Monitor> monitors: variants.instances
  property int initializedMonitors: 0
  property bool allMonitorsInitialized: false

  // === Signals ===
  signal monitorBrightnessChanged(var monitor, real newBrightness)
  signal monitorsInitialized()

  // === Public API ===
  function getMonitorForScreen(screen: ShellScreen): var {
    return monitors.find(m => m.modelData === screen)
  }

  function getAvailableMethods(): list<string> {
    // Currently only internal backlight support
    // Can't get ddcutil to work so this will be done later when i actually need it
    if (monitors.some(m => m.isAvailable)) {
      return ["internal"]
    }
    return []
  }

  // Global helpers for IPC and shortcuts
  function increaseBrightness(): void {
    monitors.forEach(m => m.increaseBrightness())
  }

  function decreaseBrightness(): void {
    monitors.forEach(m => m.decreaseBrightness())
  }

  // === Initialization ===
  Component.onCompleted: {
    QsCommons.Logger.i("BrightnessService", "Service started")
  }

  onInitializedMonitorsChanged: {
    if (initializedMonitors === monitors.length && !allMonitorsInitialized) {
      allMonitorsInitialized = true
      monitorsInitialized()
      QsCommons.Logger.d("BrightnessService", "All monitors initialized")
    }
  }

  // === Variants Pattern ===
  Variants {
    id: variants
    model: Quickshell.screens
    Monitor {}
  }

  // === Monitor Component ===
  component Monitor: QtObject {
    id: monitor

    // === Required Properties ===
    required property ShellScreen modelData

    // === State Properties ===
    property real brightness: 0.0
    property real queuedBrightness: NaN
    property bool isAvailable: false

    // Internal backlight properties
    property string backlightDevice: ""
    property string brightnessPath: ""
    property string maxBrightnessPath: ""
    property int maxBrightness: 100
    readonly property string method: "internal"  // Future: "ddcutil" or "apple"

    // === Signals ===
    signal brightnessUpdated(real newBrightness)

    // === Step Size ===
    readonly property real stepSize: QsCommons.Settings.data.brightness.step / 100.0

    // === Debounce Timer ===
    readonly property Timer timer: Timer {
      interval: 100
      onTriggered: {
        if (!isNaN(monitor.queuedBrightness)) {
          monitor.setBrightness(monitor.queuedBrightness)
          monitor.queuedBrightness = NaN
        }
      }
    }

    // === Initialization Process ===
    readonly property Process initProc: Process {
      stdout: StdioCollector {
        onStreamFinished: {
          var dataText = text.trim()
          if (dataText === "") {
            QsCommons.Logger.d("BrightnessService", "No backlight device found for", monitor.modelData.name)
            // Mark as initialized even if no backlight found
            root.initializedMonitors++
            return
          }

          // Parse internal backlight response: device_path, current_brightness, max_brightness
          var lines = dataText.split("\n")
          if (lines.length >= 3) {
            monitor.backlightDevice = lines[0]
            monitor.brightnessPath = monitor.backlightDevice + "/brightness"
            monitor.maxBrightnessPath = monitor.backlightDevice + "/max_brightness"

            var current = parseInt(lines[1])
            var max = parseInt(lines[2])
            if (!isNaN(current) && !isNaN(max) && max > 0) {
              monitor.maxBrightness = max
              monitor.brightness = current / max
              monitor.isAvailable = true
              QsCommons.Logger.i("BrightnessService", "Detected internal backlight for", monitor.modelData.name + ":", current + "/" + max, "(" + Math.round(monitor.brightness * 100) + "%)")
              QsCommons.Logger.d("BrightnessService", "Using device:", monitor.backlightDevice)
              
              // Emit initial signals
              monitor.brightnessUpdated(monitor.brightness)
              root.monitorBrightnessChanged(monitor, monitor.brightness)
            } else {
              QsCommons.Logger.d("BrightnessService", "No backlight for", monitor.modelData.name)
            }
          } else {
            QsCommons.Logger.d("BrightnessService", "No backlight for", monitor.modelData.name)
          }
          
          // Mark this monitor as initialized (whether backlight found or not)
          root.initializedMonitors++
        }
      }
    }

    // === Refresh Process (FileView callback) ===
    readonly property Process refreshProc: Process {
      stdout: StdioCollector {
        onStreamFinished: {
          var dataText = text.trim()
          if (dataText === "") {
            return
          }

          // Internal backlight only - 2 lines: current, max
          var lines = dataText.split("\n")
          if (lines.length >= 2) {
            var current = parseInt(lines[0].trim())
            var max = parseInt(lines[1].trim())
            if (!isNaN(current) && !isNaN(max) && max > 0) {
              var newBrightness = current / max
              // Only update if difference > 1% (avoid feedback loops)
              if (Math.abs(newBrightness - monitor.brightness) > 0.01) {
                monitor.brightness = newBrightness
                monitor.brightnessUpdated(monitor.brightness)
                root.monitorBrightnessChanged(monitor, monitor.brightness)
                QsCommons.Logger.d("BrightnessService", "Refreshed brightness for", monitor.modelData.name + ":", Math.round(newBrightness * 100) + "%")
              }
            }
          }
        }
      }
    }

    // === FileView Watcher (internal backlight only) ===
    readonly property FileView brightnessWatcher: FileView {
      path: (monitor.isAvailable && monitor.brightnessPath !== "") ? monitor.brightnessPath : ""
      watchChanges: path !== ""
      onFileChanged: {
        // When brightness file changes (e.g., keyboard brightness keys), refresh from system
        Qt.callLater(() => {
          monitor.refreshBrightnessFromSystem()
        })
      }
    }

    // === Functions ===
    
    function setBrightnessDebounced(value: real): void {
      monitor.queuedBrightness = value
      timer.start()
    }

    function increaseBrightness(): void {
      if (!monitor.isAvailable) {
        QsCommons.Logger.d("BrightnessService", "Brightness not available for", monitor.modelData.name)
        return
      }

      const value = !isNaN(monitor.queuedBrightness) ? 
                    monitor.queuedBrightness : monitor.brightness
      setBrightnessDebounced(Math.min(1.0, value + stepSize))
    }

    function decreaseBrightness(): void {
      if (!monitor.isAvailable) {
        QsCommons.Logger.d("BrightnessService", "Brightness not available for", monitor.modelData.name)
        return
      }

      const value = !isNaN(monitor.queuedBrightness) ? 
                    monitor.queuedBrightness : monitor.brightness
      setBrightnessDebounced(Math.max(0, value - stepSize))
    }

    function setBrightness(value: real): void {
      if (!monitor.isAvailable) {
        QsCommons.Logger.w("BrightnessService", "Brightness not available for", monitor.modelData.name)
        return
      }

      value = Math.max(0, Math.min(1, value))
      var rounded = Math.round(value * 100)

      if (timer.running) {
        monitor.queuedBrightness = value
        return
      }

      // Update internal value and trigger UI feedback
      monitor.brightness = value
      monitor.brightnessUpdated(value)
      root.monitorBrightnessChanged(monitor, monitor.brightness)

      // Apply to system - currently only internal backlight
      Quickshell.execDetached(["brightnessctl", "s", rounded + "%"])
    }

    function refreshBrightnessFromSystem(): void {
      if (!monitor.isAvailable) {
        return
      }

      // Currently only internal backlight
      refreshProc.command = ["sh", "-c", 
        "cat " + monitor.brightnessPath + " && cat " + monitor.maxBrightnessPath]
      refreshProc.running = true
    }

    function initBrightness(): void {
      // Currently only checks for internal backlight
      // Future: Will check isDdc, isAppleDisplay properties
      
      initProc.command = ["sh", "-c", 
        "for dev in /sys/class/backlight/*; do " +
        "  if [ -f \"$dev/brightness\" ] && [ -f \"$dev/max_brightness\" ]; then " +
        "    echo \"$dev\"; " +
        "    cat \"$dev/brightness\"; " +
        "    cat \"$dev/max_brightness\"; " +
        "    break; " +
        "  fi; " +
        "done"]
      initProc.running = true
    }

    // Trigger initialization when component is ready
    Component.onCompleted: initBrightness()
  }
}
