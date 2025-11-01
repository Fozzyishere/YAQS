import QtQuick
import Quickshell
import "Commons" as QsCommons
import "Services" as QsServices

ShellRoot {
  id: shellRoot

  property bool settingsLoaded: false

  Component.onCompleted: {
    QsCommons.Logger.i("Shell", "========================================")
    QsCommons.Logger.i("Shell", "YAQS Test Suite - Running All Tests")
    QsCommons.Logger.i("Shell", "========================================")
  }

  Connections {
    target: Quickshell
    function onReloadCompleted() {
      Quickshell.inhibitReloadPopup()
    }
  }

  Connections {
    target: QsCommons.Settings
    function onSettingsLoaded() {
      settingsLoaded = true
    }
  }

  Loader {
    active: settingsLoaded

    sourceComponent: Item {
      Component.onCompleted: {
        QsCommons.Logger.i("Shell", "Settings loaded successfully")
        QsCommons.Logger.i("Shell", "")

        // Force early initialization of some services
        var _ = QsServices.BrightnessService.monitors
        QsServices.NetworkService.init()
        
        // Force BluetoothService initialization early to allow D-Bus adapter discovery
        var _bt = QsServices.BluetoothService.available
        
        // Start test sequence
        runTest1_ProgramChecker()
      }

      // ========================================
      // Test 1: ProgramCheckerService
      // ========================================
      
      function runTest1_ProgramChecker() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=================================")
        QsCommons.Logger.i("Test", "Test 1: ProgramCheckerService")
        QsCommons.Logger.i("Test", "=================================")
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "Checking for required programs...")
        QsCommons.Logger.i("Test", "(Results will appear when checks complete)")
        QsCommons.Logger.i("Test", "")
      }

      Connections {
        target: QsServices.ProgramCheckerService
        function onChecksCompleted() {
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "=== Results ===")
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "Program Availability:")
          QsCommons.Logger.i("Test", "  matugen:             " + QsServices.ProgramCheckerService.matugenAvailable)
          QsCommons.Logger.i("Test", "  kitty:               " + QsServices.ProgramCheckerService.kittyAvailable)
          QsCommons.Logger.i("Test", "  foot:                " + QsServices.ProgramCheckerService.footAvailable)
          QsCommons.Logger.i("Test", "  ghostty:             " + QsServices.ProgramCheckerService.ghosttyAvailable)
          QsCommons.Logger.i("Test", "  gpu-screen-recorder: " + QsServices.ProgramCheckerService.gpuScreenRecorderAvailable)
          QsCommons.Logger.i("Test", "  nmcli:               " + QsServices.ProgramCheckerService.nmcliAvailable)
          QsCommons.Logger.i("Test", "  bluetoothctl:        " + QsServices.ProgramCheckerService.bluetoothctlAvailable)
          QsCommons.Logger.i("Test", "  brightnessctl:       " + QsServices.ProgramCheckerService.brightnessctlAvailable)
          QsCommons.Logger.i("Test", "  playerctl:           " + QsServices.ProgramCheckerService.playerctlAvailable)
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "=== Test 1 Complete ===")
          QsCommons.Logger.i("Test", "")
          
          // Start next test
          Qt.callLater(() => {
            runTest2_CompositorDetection()
            // Wait for backend initialization before testing data
            test2DataTimer.start()
          })
        }
      }

      // ========================================
      // Test 2: CompositorService
      // ========================================

      Timer {
        id: test2DataTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
          runTest2_CompositorData()
          // Wait for display scale query
          test2DisplayTimer.start()
        }
      }

      Timer {
        id: test2DisplayTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
          runTest2_DisplayScales()
          // Start next test
          Qt.callLater(() => {
            test3AudioTimer.start()
          })
        }
      }

      Connections {
        target: QsServices.CompositorService
        function onWorkspaceChanged() {
          QsCommons.Logger.d("Test", "Workspace changed event received")
        }
        function onActiveWindowChanged() {
          QsCommons.Logger.d("Test", "Active window changed event received")
        }
        function onDisplayScalesChanged() {
          QsCommons.Logger.d("Test", "Display scales updated")
        }
      }

      function runTest2_CompositorDetection() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "============================")
        QsCommons.Logger.i("Test", "Test 2: CompositorService")
        QsCommons.Logger.i("Test", "============================")
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=== Part A: Compositor Detection ===")
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Environment Variables:")
        QsCommons.Logger.i("Test", "  HYPRLAND_INSTANCE_SIGNATURE: " + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
        QsCommons.Logger.i("Test", "  NIRI_SOCKET:                 " + Quickshell.env("NIRI_SOCKET"))
        QsCommons.Logger.i("Test", "  SWAYSOCK:                    " + Quickshell.env("SWAYSOCK"))
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Detected Compositor:")
        QsCommons.Logger.i("Test", "  isHyprland: " + QsServices.CompositorService.isHyprland)
        QsCommons.Logger.i("Test", "  isNiri:     " + QsServices.CompositorService.isNiri)
        QsCommons.Logger.i("Test", "  isSway:     " + QsServices.CompositorService.isSway)
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Backend loaded:       " + (QsServices.CompositorService.backend !== null))
        QsCommons.Logger.i("Test", "Display cache path:   " + QsServices.CompositorService.displayCachePath)
        QsCommons.Logger.i("Test", "")
      }

      function runTest2_CompositorData() {
        QsCommons.Logger.i("Test", "=== Part B: Workspace & Window Data ===")
        QsCommons.Logger.i("Test", "")
        
        // Test workspace data
        QsCommons.Logger.i("Test", "Workspaces (count: " + QsServices.CompositorService.workspaces.count + "):")
        for (var i = 0; i < QsServices.CompositorService.workspaces.count; i++) {
          const ws = QsServices.CompositorService.workspaces.get(i)
          QsCommons.Logger.i("Test", "  [" + ws.id + "] " + ws.name + ": " +
            "focused=" + ws.isFocused + ", " +
            "active=" + ws.isActive + ", " +
            "occupied=" + ws.isOccupied + ", " +
            "output=" + ws.output)
        }
        QsCommons.Logger.i("Test", "")
        
        // Test window data
        QsCommons.Logger.i("Test", "Windows (count: " + QsServices.CompositorService.windows.count + "):")
        for (var i = 0; i < Math.min(QsServices.CompositorService.windows.count, 5); i++) {
          const win = QsServices.CompositorService.windows.get(i)
          QsCommons.Logger.i("Test", "  [" + win.id.substring(0, 8) + "...] " +
            "title=\"" + win.title + "\", " +
            "app=\"" + win.appId + "\", " +
            "ws=" + win.workspaceId + ", " +
            "focused=" + win.isFocused)
        }
        if (QsServices.CompositorService.windows.count > 5) {
          QsCommons.Logger.i("Test", "  ... and " + (QsServices.CompositorService.windows.count - 5) + " more")
        }
        QsCommons.Logger.i("Test", "")
        
        // Test focused window
        const focused = QsServices.CompositorService.getFocusedWindow()
        if (focused) {
          QsCommons.Logger.i("Test", "Focused Window:")
          QsCommons.Logger.i("Test", "  title:     \"" + focused.title + "\"")
          QsCommons.Logger.i("Test", "  app:       \"" + focused.appId + "\"")
          QsCommons.Logger.i("Test", "  workspace: " + focused.workspaceId)
        } else {
          QsCommons.Logger.i("Test", "No focused window")
        }
        QsCommons.Logger.i("Test", "")
        
        // Test current workspace
        const currentWs = QsServices.CompositorService.getCurrentWorkspace()
        if (currentWs) {
          QsCommons.Logger.i("Test", "Current Workspace:")
          QsCommons.Logger.i("Test", "  id:     " + currentWs.id)
          QsCommons.Logger.i("Test", "  name:   " + currentWs.name)
          QsCommons.Logger.i("Test", "  output: " + currentWs.output)
        }
        QsCommons.Logger.i("Test", "")
        
        // Trigger display scale query
        QsCommons.Logger.i("Test", "Querying display scales...")
        QsServices.CompositorService.updateDisplayScales()
      }

      function runTest2_DisplayScales() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=== Part C: Display Scales ===")
        QsCommons.Logger.i("Test", "")
        
        const scales = QsServices.CompositorService.displayScales
        const displayNames = Object.keys(scales)
        
        if (displayNames.length === 0) {
          QsCommons.Logger.i("Test", "  No displays detected yet")
        } else {
          for (var i = 0; i < displayNames.length; i++) {
            const name = displayNames[i]
            const info = scales[name]
            QsCommons.Logger.i("Test", "Display: " + name)
            QsCommons.Logger.i("Test", "  resolution:  " + info.width + "x" + info.height)
            QsCommons.Logger.i("Test", "  scale:       " + info.scale)
            QsCommons.Logger.i("Test", "  refresh:     " + info.refresh_rate + " Hz")
            QsCommons.Logger.i("Test", "  position:    (" + info.x + ", " + info.y + ")")
            QsCommons.Logger.i("Test", "  vrr:         " + info.vrr)
            QsCommons.Logger.i("Test", "  focused:     " + info.focused)
            QsCommons.Logger.i("Test", "")
          }
        }
        
        QsCommons.Logger.i("Test", "Cache file: " + QsServices.CompositorService.displayCachePath)
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=== Test 2 Complete ===")
        QsCommons.Logger.i("Test", "")
      }

      // ========================================
      // Test 3: AudioService
      // ========================================

      Timer {
        id: test3AudioTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: runTest3_AudioService()
      }

      function runTest3_AudioService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "======================")
        QsCommons.Logger.i("Test", "Test 3: AudioService")
        QsCommons.Logger.i("Test", "======================")
        QsCommons.Logger.i("Test", "")
        
        // Test output devices
        QsCommons.Logger.i("Test", "Output Devices (Sinks) - count: " + QsServices.AudioService.sinks.length)
        for (var i = 0; i < QsServices.AudioService.sinks.length; i++) {
          const sink = QsServices.AudioService.sinks[i]
          const isDefault = (sink === QsServices.AudioService.sink)
          QsCommons.Logger.i("Test", "  [" + i + "] " + sink.name +
            (isDefault ? " (DEFAULT)" : "") +
            " - vol: " + Math.round(sink.audio.volume * 100) + "%, " +
            "muted: " + sink.audio.muted)
        }
        QsCommons.Logger.i("Test", "")
        
        // Test input devices
        QsCommons.Logger.i("Test", "Input Devices (Sources) - count: " + QsServices.AudioService.sources.length)
        for (var i = 0; i < QsServices.AudioService.sources.length; i++) {
          const source = QsServices.AudioService.sources[i]
          const isDefault = (source === QsServices.AudioService.source)
          QsCommons.Logger.i("Test", "  [" + i + "] " + source.name +
            (isDefault ? " (DEFAULT)" : "") +
            " - vol: " + Math.round(source.audio.volume * 100) + "%, " +
            "muted: " + source.audio.muted)
        }
        QsCommons.Logger.i("Test", "")
        
        // Test default sink state
        if (QsServices.AudioService.sink) {
          QsCommons.Logger.i("Test", "Default Output:")
          QsCommons.Logger.i("Test", "  name:        " + QsServices.AudioService.sink.name)
          QsCommons.Logger.i("Test", "  description: " + QsServices.AudioService.sink.description)
          QsCommons.Logger.i("Test", "  volume:      " + Math.round(QsServices.AudioService.volume * 100) + "%")
          QsCommons.Logger.i("Test", "  muted:       " + QsServices.AudioService.muted)
        } else {
          QsCommons.Logger.i("Test", "No default output device")
        }
        QsCommons.Logger.i("Test", "")
        
        // Test default source state
        if (QsServices.AudioService.source) {
          QsCommons.Logger.i("Test", "Default Input:")
          QsCommons.Logger.i("Test", "  name:        " + QsServices.AudioService.source.name)
          QsCommons.Logger.i("Test", "  description: " + QsServices.AudioService.source.description)
          QsCommons.Logger.i("Test", "  volume:      " + Math.round(QsServices.AudioService.inputVolume * 100) + "%")
          QsCommons.Logger.i("Test", "  muted:       " + QsServices.AudioService.inputMuted)
        } else {
          QsCommons.Logger.i("Test", "No default input device")
        }
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Settings:")
        QsCommons.Logger.i("Test", "  volumeStep:      " + QsCommons.Settings.data.audio.volumeStep)
        QsCommons.Logger.i("Test", "  volumeOverdrive: " + QsCommons.Settings.data.audio.volumeOverdrive)
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "=== Test 3 Complete ===")
        QsCommons.Logger.i("Test", "")
        
        // Small delay to allow BrightnessService async init to complete
        Qt.callLater(() => {
          test4Timer.start()
        })
      }

      // ========================================
      // Test 4: BrightnessService
      // ========================================
      // Note: BrightnessService initializes at startup, but detection is async.
      // We add a small delay to ensure the Process completes.

      Timer {
        id: test4Timer
        interval: 500
        running: false
        repeat: false
        onTriggered: runTest4_BrightnessService()
      }

      function runTest4_BrightnessService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "===========================")
        QsCommons.Logger.i("Test", "Test 4: BrightnessService")
        QsCommons.Logger.i("Test", "===========================")
        QsCommons.Logger.i("Test", "")
        
        // Test monitor detection
        QsCommons.Logger.i("Test", "Detected Monitors: " + QsServices.BrightnessService.monitors.length)
        for (var i = 0; i < QsServices.BrightnessService.monitors.length; i++) {
          const monitor = QsServices.BrightnessService.monitors[i]
          QsCommons.Logger.i("Test", "  [" + i + "] " + monitor.modelData.name)
          QsCommons.Logger.i("Test", "      Available:  " + monitor.isAvailable)
          if (monitor.isAvailable) {
            QsCommons.Logger.i("Test", "      Method:     " + monitor.method)
            QsCommons.Logger.i("Test", "      Device:     " + (monitor.backlightDevice || "N/A"))
            QsCommons.Logger.i("Test", "      Brightness: " + Math.round(monitor.brightness * 100) + "%")
            QsCommons.Logger.i("Test", "      Max Value:  " + monitor.maxBrightness)
          }
        }
        QsCommons.Logger.i("Test", "")
        
        // Test available methods
        const methods = QsServices.BrightnessService.getAvailableMethods()
        QsCommons.Logger.i("Test", "Available Methods: " + (methods.length > 0 ? methods.join(", ") : "None"))
        if (methods.length === 0) {
          QsCommons.Logger.i("Test", "  (This is normal for desktop systems without internal backlights)")
        }
        QsCommons.Logger.i("Test", "")
        
        // Test settings
        QsCommons.Logger.i("Test", "Settings:")
        QsCommons.Logger.i("Test", "  brightnessStep: " + QsCommons.Settings.data.brightness.step)
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "=== Test 4 Complete ===")
        QsCommons.Logger.i("Test", "")

        // Proceed to network service tests
        Qt.callLater(() => {
          test5NetworkTimer.start()
        })
      }

      // TODO:
      // - Background
      // - Bar
      // - ControlCenter
      // - Dock
      // - Launcher
      // - LockScreen
      // - Notification
      // - OSD
      // - SessionMenu
      // - Toast
      // - Tooltip
      // - Wallpaper
      
      // ========================================
      // Test 5: NetworkService
      // ========================================

      Timer {
        id: test5NetworkTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: runTest5_NetworkService()
      }

      Timer {
        id: test5NetworkResultsTimer
        interval: 5000
        running: false
        repeat: false
        onTriggered: runTest5_NetworkServiceResults()
      }

      function runTest5_NetworkService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=========================")
        QsCommons.Logger.i("Test", "Test 5: NetworkService")
        QsCommons.Logger.i("Test", "=========================")
        QsCommons.Logger.i("Test", "")

        if (!QsServices.ProgramCheckerService.nmcliAvailable) {
          QsCommons.Logger.w("Test", "nmcli not available; NetworkService initialization skipped")
          QsCommons.Logger.i("Test", "")
          finalizeTestSuite()
          return
        }

        QsCommons.Logger.i("Test", "Waiting for Wi-Fi scan results...")
        QsCommons.Logger.i("Test", "")
        test5NetworkResultsTimer.start()
      }

      function runTest5_NetworkServiceResults() {
        const nets = QsServices.NetworkService.networks
        const ssids = Object.keys(nets)

        QsCommons.Logger.i("Test", "Wi-Fi Enabled: " + QsCommons.Settings.data.network.wifiEnabled)
        QsCommons.Logger.i("Test", "Ethernet Connected: " + QsServices.NetworkService.ethernetConnected)
        QsCommons.Logger.i("Test", "Active Scan: " + QsServices.NetworkService.scanning)
        QsCommons.Logger.i("Test", "Networks Found: " + ssids.length)

        for (var i = 0; i < Math.min(ssids.length, 5); i++) {
          const ssid = ssids[i]
          const net = nets[ssid]
          QsCommons.Logger.i("Test", "  [" + i + "] " + ssid + ":")
          QsCommons.Logger.i("Test", "      Signal:    " + net.signal + "%")
          QsCommons.Logger.i("Test", "      Security:  " + net.security)
          QsCommons.Logger.i("Test", "      Connected: " + net.connected)
          QsCommons.Logger.i("Test", "      Saved:     " + net.existing)
          QsCommons.Logger.i("Test", "      Cached:    " + net.cached)
        }

        if (ssids.length > 5) {
          QsCommons.Logger.i("Test", "  ... and " + (ssids.length - 5) + " more")
        }

        if (QsServices.NetworkService.lastError) {
          QsCommons.Logger.w("Test", "Last error: " + QsServices.NetworkService.lastError)
        }

        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=== Test 5 Complete ===")
        QsCommons.Logger.i("Test", "")

        // Proceed to Bluetooth test
        Qt.callLater(() => {
          test6BluetoothTimer.start()
        })
      }

      // ========================================
      // Test 6: BluetoothService
      // ========================================
      // Note: Bluetooth adapter needs ~2s to initialize via D-Bus

      Timer {
        id: test6BluetoothTimer
        interval: 3000  // 3s delay to allow Bluetooth D-Bus initialization
        running: false
        repeat: false
        onTriggered: runTest6_BluetoothService()
      }

      function runTest6_BluetoothService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "===========================")
        QsCommons.Logger.i("Test", "Test 6: BluetoothService")
        QsCommons.Logger.i("Test", "===========================")
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "(Waited 3s for Bluetooth D-Bus initialization)")
        QsCommons.Logger.i("Test", "")

        if (!QsServices.ProgramCheckerService.bluetoothctlAvailable) {
          QsCommons.Logger.w("Test", "bluetoothctl not available; Bluetooth features may be limited")
        }

        // Check adapter availability
        QsCommons.Logger.i("Test", "Adapter Available: " + QsServices.BluetoothService.available)
        
        if (!QsServices.BluetoothService.available) {
          QsCommons.Logger.w("Test", "No Bluetooth adapter found")
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "=== Test 6 Complete ===")
          QsCommons.Logger.i("Test", "")
          finalizeTestSuite()
          return
        }

        QsCommons.Logger.i("Test", "Bluetooth Enabled: " + QsServices.BluetoothService.enabled)
        QsCommons.Logger.i("Test", "Discovering: " + QsServices.BluetoothService.discovering)
        QsCommons.Logger.i("Test", "")

        // Display paired devices
        const paired = QsServices.BluetoothService.pairedDevices
        QsCommons.Logger.i("Test", "Paired Devices: " + paired.length)
        
        for (var i = 0; i < Math.min(paired.length, 5); i++) {
          const device = paired[i]
          QsCommons.Logger.i("Test", "  [" + i + "] " + (device.name || device.address))
          QsCommons.Logger.i("Test", "      Address:   " + device.address)
          QsCommons.Logger.i("Test", "      Connected: " + device.connected)
          QsCommons.Logger.i("Test", "      Trusted:   " + device.trusted)
          QsCommons.Logger.i("Test", "      Icon:      " + QsServices.BluetoothService.getDeviceIcon(device))
          
          if (device.batteryAvailable) {
            QsCommons.Logger.i("Test", "      " + QsServices.BluetoothService.getBattery(device))
          }
          
          if (device.signalStrength !== undefined && device.signalStrength > 0) {
            QsCommons.Logger.i("Test", "      " + QsServices.BluetoothService.getSignalStrength(device))
          }
        }
        
        if (paired.length > 5) {
          QsCommons.Logger.i("Test", "  ... and " + (paired.length - 5) + " more")
        }
        
        QsCommons.Logger.i("Test", "")

        // Display connected devices
        const connected = QsServices.BluetoothService.connectedDevices
        QsCommons.Logger.i("Test", "Connected Devices: " + connected.length)
        
        for (var j = 0; j < connected.length; j++) {
          const dev = connected[j]
          QsCommons.Logger.i("Test", "  [" + j + "] " + (dev.name || dev.address))
        }
        
        QsCommons.Logger.i("Test", "")

        // Display devices with battery
        const withBattery = QsServices.BluetoothService.allDevicesWithBattery
        QsCommons.Logger.i("Test", "Devices with Battery Info: " + withBattery.length)
        
        for (var k = 0; k < withBattery.length; k++) {
          const battDev = withBattery[k]
          QsCommons.Logger.i("Test", "  [" + k + "] " + (battDev.name || battDev.address) + 
                             " - " + Math.round(battDev.battery * 100) + "%")
        }
        
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=== Test 6 Complete ===")
        QsCommons.Logger.i("Test", "")

        finalizeTestSuite()
      }

      function finalizeTestSuite() {
        Qt.callLater(() => {
          QsCommons.Logger.i("Shell", "")
          QsCommons.Logger.i("Shell", "========================================")
          QsCommons.Logger.i("Shell", "All Tests Complete")
          QsCommons.Logger.i("Shell", "========================================")
          QsCommons.Logger.i("Shell", "")
        })
      }
    }
  }
}
