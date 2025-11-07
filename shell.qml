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

        // Initialize theming services
        QsServices.WallpaperService.init()
        QsServices.ColorSchemeService.init()

        // Force early initialization of some services
        var _ = QsServices.BrightnessService.monitors
        QsServices.NetworkService.init()
        
        // Force BluetoothService initialization early to allow D-Bus adapter discovery
        var _bt = QsServices.BluetoothService.available
        
        // Force MediaService initialization early to allow MPRIS discovery
        var _media = QsServices.MediaService.currentPlayer
        
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
          
          // Proceed to Media test
          Qt.callLater(() => {
            test7MediaTimer.start()
          })
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

        // Proceed to Media test
        Qt.callLater(() => {
          test7MediaTimer.start()
        })
      }

      // ========================================
      // Test 7: MediaService
      // ========================================

      Timer {
        id: test7MediaTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: runTest7_MediaService()
      }

      function runTest7_MediaService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "======================")
        QsCommons.Logger.i("Test", "Test 7: MediaService")
        QsCommons.Logger.i("Test", "======================")
        QsCommons.Logger.i("Test", "")
        
        // Note: Can't access Mpris directly from shell.qml scope
        // MediaService has detailed logging in getAvailablePlayers()
        
        // Test available players
        const players = QsServices.MediaService.getAvailablePlayers()
        QsCommons.Logger.i("Test", "Available Players: " + players.length)
        
        for (var i = 0; i < players.length; i++) {
          const player = players[i]
          QsCommons.Logger.i("Test", "  [" + i + "] " + player.identity)
          QsCommons.Logger.i("Test", "      Playing:     " + 
            (player.isPlaying || false))
          QsCommons.Logger.i("Test", "      Can Control: " + player.canControl)
          if (player._controlTarget) {
            QsCommons.Logger.i("Test", "      Virtual:     true (paired player)")
          }
        }
        QsCommons.Logger.i("Test", "")
        
        // Test current player
        if (QsServices.MediaService.currentPlayer) {
          QsCommons.Logger.i("Test", "Current Player:")
          QsCommons.Logger.i("Test", "  Identity:  " + 
            QsServices.MediaService.currentPlayer.identity)
          QsCommons.Logger.i("Test", "  Playing:   " + 
            QsServices.MediaService.isPlaying)
          QsCommons.Logger.i("Test", "  Track:     \"" + 
            QsServices.MediaService.trackTitle + "\"")
          QsCommons.Logger.i("Test", "  Artist:    \"" + 
            QsServices.MediaService.trackArtist + "\"")
          QsCommons.Logger.i("Test", "  Album:     \"" + 
            QsServices.MediaService.trackAlbum + "\"")
          QsCommons.Logger.i("Test", "  Art URL:   " + 
            (QsServices.MediaService.trackArtUrl ? "Yes" : "No"))
          QsCommons.Logger.i("Test", "  Position:  " + 
            Math.round(QsServices.MediaService.currentPosition) + "s / " +
            Math.round(QsServices.MediaService.trackLength) + "s")
          QsCommons.Logger.i("Test", "")
          
          QsCommons.Logger.i("Test", "Capabilities:")
          QsCommons.Logger.i("Test", "  Can Play:     " + 
            QsServices.MediaService.canPlay)
          QsCommons.Logger.i("Test", "  Can Pause:    " + 
            QsServices.MediaService.canPause)
          QsCommons.Logger.i("Test", "  Can Next:     " + 
            QsServices.MediaService.canGoNext)
          QsCommons.Logger.i("Test", "  Can Previous: " + 
            QsServices.MediaService.canGoPrevious)
          QsCommons.Logger.i("Test", "  Can Seek:     " + 
            QsServices.MediaService.canSeek)
        } else {
          QsCommons.Logger.i("Test", "No active media player")
          QsCommons.Logger.i("Test", "  (Start a media player like Spotify, VLC, or a browser video)")
        }
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Settings:")
        QsCommons.Logger.i("Test", "  mprisBlacklist:  " + 
          JSON.stringify(QsCommons.Settings.data.audio.mprisBlacklist))
        QsCommons.Logger.i("Test", "  preferredPlayer: " + 
          QsCommons.Settings.data.audio.preferredPlayer)
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "=== Test 7 Complete ===")
        QsCommons.Logger.i("Test", "")
        
        // Continue to ClipboardService test
        Qt.callLater(() => {
          test8ClipboardTimer.start()
        })
      }

      // ========================================
      // Test 8: ClipboardService
      // ========================================

      Timer {
        id: test8ClipboardTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: runTest8_ClipboardService()
      }

      function runTest8_ClipboardService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "============================")
        QsCommons.Logger.i("Test", "Test 8: ClipboardService")
        QsCommons.Logger.i("Test", "============================")
        QsCommons.Logger.i("Test", "")
        
        if (!QsServices.ClipboardService.cliphistAvailable) {
          QsCommons.Logger.w("Test", "cliphist not available; test skipped")
          QsCommons.Logger.i("Test", "  (Install cliphist to enable clipboard history)")
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "=== Test 8 Complete ===")
          QsCommons.Logger.i("Test", "")
          
          // Continue to NotificationService test
          Qt.callLater(() => {
            test9NotificationTimer.start()
          })
          return
        }
        
        QsCommons.Logger.i("Test", "cliphist available: " + 
          QsServices.ClipboardService.cliphistAvailable)
        QsCommons.Logger.i("Test", "Active: " + 
          QsServices.ClipboardService.active)
        QsCommons.Logger.i("Test", "Watchers Started: " + 
          QsServices.ClipboardService.watchersStarted)
        QsCommons.Logger.i("Test", "")
        
        // Enable feature in settings for test
        if (!QsCommons.Settings.data.appLauncher.enableClipboardHistory) {
          QsCommons.Logger.i("Test", "Enabling clipboard history in settings...")
          QsCommons.Settings.data.appLauncher.enableClipboardHistory = true
          Qt.callLater(() => {
            QsCommons.Logger.i("Test", "Active after enable: " + 
              QsServices.ClipboardService.active)
            QsCommons.Logger.i("Test", "")
          })
        }
        
        // List clipboard items
        QsCommons.Logger.i("Test", "Querying clipboard history...")
        QsServices.ClipboardService.list()
        
        // Wait for list to complete
        listCompletedConnection.enabled = true
      }

      Connections {
        id: listCompletedConnection
        target: QsServices.ClipboardService
        enabled: false
        
        function onListCompleted() {
          listCompletedConnection.enabled = false
          
          const items = QsServices.ClipboardService.items
          QsCommons.Logger.i("Test", "Clipboard Items: " + items.length)
          QsCommons.Logger.i("Test", "")
          
          if (items.length === 0) {
            QsCommons.Logger.i("Test", "  (No clipboard history found)")
            QsCommons.Logger.i("Test", "  (Copy some text or images to test clipboard history)")
          } else {
            for (var i = 0; i < Math.min(items.length, 5); i++) {
              const item = items[i]
              const preview = item.preview.substring(0, 60)
              QsCommons.Logger.i("Test", "  [" + i + "] ID: " + item.id)
              QsCommons.Logger.i("Test", "      Preview: " + 
                (preview.length < item.preview.length ? preview + "..." : preview))
              QsCommons.Logger.i("Test", "      MIME:    " + item.mime)
              QsCommons.Logger.i("Test", "      Image:   " + item.isImage)
            }
            
            if (items.length > 5) {
              QsCommons.Logger.i("Test", "  ... and " + (items.length - 5) + " more")
            }
          }
          
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "Settings:")
          QsCommons.Logger.i("Test", "  enableClipboardHistory: " + 
            QsCommons.Settings.data.appLauncher.enableClipboardHistory)
          QsCommons.Logger.i("Test", "")
          
          QsCommons.Logger.i("Test", "=== Test 8 Complete ===")
          QsCommons.Logger.i("Test", "")
          
          // Continue to NotificationService test
          Qt.callLater(() => {
            test9NotificationTimer.start()
          })
        }
      }

      // ========================================
      // Test 9: NotificationService
      // ========================================

      Timer {
        id: test9NotificationTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: runTest9_NotificationService()
      }

      function runTest9_NotificationService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "Test 9: NotificationService")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Service Initialized: true")
        QsCommons.Logger.i("Test", "Active Notifications: " + 
          QsServices.NotificationService.activeList.count)
        QsCommons.Logger.i("Test", "History Count: " + 
          QsServices.NotificationService.historyList.count)
        QsCommons.Logger.i("Test", "Max Visible: " + 
          QsServices.NotificationService.maxVisible)
        QsCommons.Logger.i("Test", "Max History: " + 
          QsServices.NotificationService.maxHistory)
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Persistence:")
        QsCommons.Logger.i("Test", "  History File: " + 
          QsServices.NotificationService.historyFile)
        QsCommons.Logger.i("Test", "  State File:   " + 
          QsServices.NotificationService.stateFile)
        QsCommons.Logger.i("Test", "  Last Seen:    " + 
          (QsServices.NotificationService.lastSeenTs ? 
           new Date(QsServices.NotificationService.lastSeenTs).toLocaleString() : 
           "Never"))
        QsCommons.Logger.i("Test", "")
        
        // Display recent history
        if (QsServices.NotificationService.historyList.count > 0) {
          QsCommons.Logger.i("Test", "Recent History (showing up to 5):")
          for (var i = 0; i < Math.min(5, QsServices.NotificationService.historyList.count); i++) {
            const notif = QsServices.NotificationService.historyList.get(i)
            const summary = notif.summary.substring(0, 40)
            const body = notif.body ? notif.body.substring(0, 40) : ""
            
            QsCommons.Logger.i("Test", "  [" + i + "] " + notif.appName)
            QsCommons.Logger.i("Test", "      Summary: " + 
              (summary.length < notif.summary.length ? summary + "..." : summary))
            if (body) {
              QsCommons.Logger.i("Test", "      Body:    " + 
                (body.length < notif.body.length ? body + "..." : body))
            }
            QsCommons.Logger.i("Test", "      Time:    " + notif.timestamp.toLocaleTimeString())
            QsCommons.Logger.i("Test", "      Urgency: " + 
              (notif.urgency === 0 ? "Low" : notif.urgency === 1 ? "Normal" : "Critical"))
          }
          
          if (QsServices.NotificationService.historyList.count > 5) {
            QsCommons.Logger.i("Test", "  ... and " + 
              (QsServices.NotificationService.historyList.count - 5) + " more")
          }
        } else {
          QsCommons.Logger.i("Test", "No notification history")
          QsCommons.Logger.i("Test", "  (Send test notifications with: notify-send)")
        }
        QsCommons.Logger.i("Test", "")
        
        // Test settings
        const notifSettings = QsCommons.Settings.data.notifications
        if (notifSettings) {
          QsCommons.Logger.i("Test", "Settings:")
          QsCommons.Logger.i("Test", "  Do Not Disturb:         " + 
            (notifSettings.doNotDisturb || false))
          QsCommons.Logger.i("Test", "  Respect Expire Timeout: " + 
            (notifSettings.respectExpireTimeout !== false))
          QsCommons.Logger.i("Test", "  Low Urgency Duration:   " + 
            (notifSettings.lowUrgencyDuration || 3) + "s")
          QsCommons.Logger.i("Test", "  Normal Duration:        " + 
            (notifSettings.normalUrgencyDuration || 8) + "s")
          QsCommons.Logger.i("Test", "  Critical Duration:      " + 
            (notifSettings.criticalUrgencyDuration || 15) + "s")
        } else {
          QsCommons.Logger.i("Test", "Settings: Using defaults (notifications not configured)")
        }
        QsCommons.Logger.i("Test", "")
        
        // Suggest manual testing
        QsCommons.Logger.i("Test", "Manual Testing Commands:")
        QsCommons.Logger.i("Test", "  Basic:     notify-send \"Test\" \"This is a test notification\"")
        QsCommons.Logger.i("Test", "  With icon: notify-send -i dialog-information \"Test\" \"Message\"")
        QsCommons.Logger.i("Test", "  Critical:  notify-send -u critical \"Important\" \"Urgent message\"")
        QsCommons.Logger.i("Test", "  Expire:    notify-send -t 2000 \"Quick\" \"Disappears in 2s\"")
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Image Caching:")
        QsCommons.Logger.i("Test", "  Cache Dir: " + 
          QsCommons.Settings.cacheDirImagesNotifications)
        QsCommons.Logger.i("Test", "  Queue:     " + 
          QsServices.NotificationService.imageQueue.length + " pending")
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "=== Test 9 Complete ===")
        QsCommons.Logger.i("Test", "")
        
        // Continue to CalendarService test
        Qt.callLater(() => {
          test10CalendarTimer.start()
        })
      }

      // ========================================
      // Test 10: CalendarService
      // ========================================

      Timer {
        id: test10CalendarTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: runTest10_CalendarService()
      }

      Connections {
        id: calendarAvailabilityConnection
        target: QsServices.CalendarService
        enabled: false
        
        function onAvailabilityCheckCompleted() {
          calendarAvailabilityConnection.enabled = false
          displayCalendarTestResults()
        }
      }

      function runTest10_CalendarService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "Test 10: CalendarService")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "")
        
        // Check if availability check already completed
        if (QsServices.CalendarService.availabilityChecked) {
          QsCommons.Logger.i("Test", "Availability check already completed")
          displayCalendarTestResults()
        } else {
          QsCommons.Logger.i("Test", "Waiting for availability check...")
          // Wait for availability check to complete
          calendarAvailabilityConnection.enabled = true
        }
      }
      
      function displayCalendarTestResults() {
        // Basic status
        QsCommons.Logger.i("Test", "Service Status:")
        QsCommons.Logger.i("Test", "  Available:  " + QsServices.CalendarService.available)
        QsCommons.Logger.i("Test", "  Loading:    " + QsServices.CalendarService.loading)
        QsCommons.Logger.i("Test", "")
        
        // Settings
        const calSettings = QsCommons.Settings.data.calendar
        QsCommons.Logger.i("Test", "Settings:")
        QsCommons.Logger.i("Test", "  Enabled:         " + (calSettings ? calSettings.enabled : "undefined"))
        QsCommons.Logger.i("Test", "  Auto-Refresh:    " + (calSettings ? calSettings.autoRefresh : "undefined"))
        QsCommons.Logger.i("Test", "  Refresh Interval: " + (calSettings ? calSettings.refreshInterval / 1000 : "undefined") + "s")
        QsCommons.Logger.i("Test", "  Days Ahead:      " + (calSettings ? calSettings.daysAhead : "undefined"))
        QsCommons.Logger.i("Test", "  Days Behind:     " + (calSettings ? calSettings.daysBehind : "undefined"))
        QsCommons.Logger.i("Test", "")
        
        // Check availability status
        if (!QsServices.CalendarService.available) {
          QsCommons.Logger.w("Test", "Calendar not available:")
          if (QsServices.CalendarService.lastError) {
            QsCommons.Logger.w("Test", "  Error: " + QsServices.CalendarService.lastError)
          }
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "Dependencies:")
          QsCommons.Logger.i("Test", "  - python3 (required)")
          QsCommons.Logger.i("Test", "  - python3-gi (required)")
          QsCommons.Logger.i("Test", "  - evolution-data-server (required)")
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "Install on Arch Linux:")
          QsCommons.Logger.i("Test", "  sudo pacman -S python python-gobject evolution-data-server")
          QsCommons.Logger.i("Test", "")
          
          // Show cached data if available
          if (QsServices.CalendarService.calendars.length > 0) {
            QsCommons.Logger.i("Test", "Cached Calendars: " + QsServices.CalendarService.calendars.length)
            for (var i = 0; i < Math.min(3, QsServices.CalendarService.calendars.length); i++) {
              const cal = QsServices.CalendarService.calendars[i]
              QsCommons.Logger.i("Test", "  [" + i + "] " + cal.name)
            }
          }
          
          if (QsServices.CalendarService.events.length > 0) {
            QsCommons.Logger.i("Test", "")
            QsCommons.Logger.i("Test", "Cached Events: " + QsServices.CalendarService.events.length)
            for (var i = 0; i < Math.min(3, QsServices.CalendarService.events.length); i++) {
              const event = QsServices.CalendarService.events[i]
              const startDate = new Date(event.start * 1000)
              QsCommons.Logger.i("Test", "  [" + i + "] " + event.summary)
              QsCommons.Logger.i("Test", "      Calendar: " + event.calendar)
              QsCommons.Logger.i("Test", "      Start:    " + startDate.toLocaleString())
              if (event.location) {
                QsCommons.Logger.i("Test", "      Location: " + event.location)
              }
            }
          }
          
          QsCommons.Logger.i("Test", "")
          QsCommons.Logger.i("Test", "=== Test 10 Complete ===")
          QsCommons.Logger.i("Test", "")
          
          finalizeTestSuite()
          return
        }
        
        // Service is available - show data
        QsCommons.Logger.i("Test", "Evolution Data Server: Available ✓")
        QsCommons.Logger.i("Test", "")
        
        // Calendars
        QsCommons.Logger.i("Test", "Calendars: " + QsServices.CalendarService.calendars.length)
        for (var i = 0; i < Math.min(5, QsServices.CalendarService.calendars.length); i++) {
          const cal = QsServices.CalendarService.calendars[i]
          QsCommons.Logger.i("Test", "  [" + i + "] " + cal.name)
          QsCommons.Logger.i("Test", "      UID:     " + cal.uid)
          QsCommons.Logger.i("Test", "      Enabled: " + cal.enabled)
        }
        
        if (QsServices.CalendarService.calendars.length > 5) {
          QsCommons.Logger.i("Test", "  ... and " + 
            (QsServices.CalendarService.calendars.length - 5) + " more")
        }
        QsCommons.Logger.i("Test", "")
        
        // Events
        QsCommons.Logger.i("Test", "Events: " + QsServices.CalendarService.events.length)
        
        if (QsServices.CalendarService.events.length === 0) {
          QsCommons.Logger.i("Test", "  (No events found in date range)")
          QsCommons.Logger.i("Test", "  (Add events in GNOME Calendar to test)")
        } else {
          for (var i = 0; i < Math.min(5, QsServices.CalendarService.events.length); i++) {
            const event = QsServices.CalendarService.events[i]
            const startDate = new Date(event.start * 1000)
            const endDate = new Date(event.end * 1000)
            const duration = (event.end - event.start) / 3600  // hours
            
            QsCommons.Logger.i("Test", "  [" + i + "] " + event.summary)
            QsCommons.Logger.i("Test", "      Calendar: " + event.calendar)
            QsCommons.Logger.i("Test", "      Start:    " + startDate.toLocaleString())
            QsCommons.Logger.i("Test", "      End:      " + endDate.toLocaleString())
            QsCommons.Logger.i("Test", "      Duration: " + duration.toFixed(1) + " hours")
            
            if (event.location) {
              QsCommons.Logger.i("Test", "      Location: " + event.location)
            }
            
            if (event.description && event.description.length > 0) {
              const desc = event.description.substring(0, 60)
              QsCommons.Logger.i("Test", "      Desc:     " + 
                (desc.length < event.description.length ? desc + "..." : desc))
            }
          }
          
          if (QsServices.CalendarService.events.length > 5) {
            QsCommons.Logger.i("Test", "  ... and " + 
              (QsServices.CalendarService.events.length - 5) + " more")
          }
        }
        
        QsCommons.Logger.i("Test", "")
        
        // Cache info
        QsCommons.Logger.i("Test", "Cache:")
        QsCommons.Logger.i("Test", "  File: " + QsServices.CalendarService.cacheFile)
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Manual Testing:")
        QsCommons.Logger.i("Test", "  1. Install GNOME Calendar: sudo pacman -S gnome-calendar")
        QsCommons.Logger.i("Test", "  2. Add some events in GNOME Calendar")
        QsCommons.Logger.i("Test", "  3. Reload shell to see events: quickshell --replace")
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "=== Test 10 Complete ===")
        QsCommons.Logger.i("Test", "")
        
        // Continue to ColorSchemeService test
        Qt.callLater(() => {
          runTest11_ColorSchemeService()
        })
      }

      // ========================================
      // Test 11: ColorSchemeService
      // ========================================

      function runTest11_ColorSchemeService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "Test 11: ColorSchemeService")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "")
        
        // Service status
        QsCommons.Logger.i("Test", "Service Status:")
        QsCommons.Logger.i("Test", "  Scanning:      " + QsServices.ColorSchemeService.scanning)
        QsCommons.Logger.i("Test", "  Schemes Found: " + QsServices.ColorSchemeService.schemes.length)
        QsCommons.Logger.i("Test", "")
        
        // Settings
        QsCommons.Logger.i("Test", "Settings:")
        QsCommons.Logger.i("Test", "  Use Wallpaper:  " + QsCommons.Settings.data.colorSchemes.useWallpaperColors)
        QsCommons.Logger.i("Test", "  Current Scheme: " + QsCommons.Settings.data.colorSchemes.predefinedScheme)
        QsCommons.Logger.i("Test", "  Dark Mode:      " + QsCommons.Settings.data.colorSchemes.darkMode)
        QsCommons.Logger.i("Test", "")
        
        // List available schemes (first 10)
        if (QsServices.ColorSchemeService.schemes.length > 0) {
          QsCommons.Logger.i("Test", "Available Schemes:")
          for (var i = 0; i < Math.min(10, QsServices.ColorSchemeService.schemes.length); i++) {
            const schemePath = QsServices.ColorSchemeService.schemes[i]
            const displayName = QsServices.ColorSchemeService.getBasename(schemePath)
            QsCommons.Logger.i("Test", "  [" + i + "] " + displayName)
          }
          if (QsServices.ColorSchemeService.schemes.length > 10) {
            QsCommons.Logger.i("Test", "  ... and " + 
              (QsServices.ColorSchemeService.schemes.length - 10) + " more")
          }
        } else {
          QsCommons.Logger.w("Test", "No color schemes found!")
          QsCommons.Logger.w("Test", "Expected directory: " + QsServices.ColorSchemeService.schemesDirectory)
        }
        QsCommons.Logger.i("Test", "")
        
        // Color output file
        QsCommons.Logger.i("Test", "Color Output:")
        QsCommons.Logger.i("Test", "  File: " + QsServices.ColorSchemeService.colorsJsonFilePath)
        QsCommons.Logger.i("Test", "")
        
        // Current colors (from Color.qml)
        QsCommons.Logger.i("Test", "Active Colors (Material Design 3):")
        QsCommons.Logger.i("Test", "  Primary:        " + QsCommons.Color.mPrimary)
        QsCommons.Logger.i("Test", "  On Primary:     " + QsCommons.Color.mOnPrimary)
        QsCommons.Logger.i("Test", "  Secondary:      " + QsCommons.Color.mSecondary)
        QsCommons.Logger.i("Test", "  Surface:        " + QsCommons.Color.mSurface)
        QsCommons.Logger.i("Test", "  On Surface:     " + QsCommons.Color.mOnSurface)
        QsCommons.Logger.i("Test", "  Error:          " + QsCommons.Color.mError)
        QsCommons.Logger.i("Test", "")
        
        // Verify scheme application worked
        if (QsServices.ColorSchemeService.schemes.length > 0) {
          if (QsCommons.Color.mPrimary !== "#000000" || QsCommons.Color.mSurface !== "#ffffff") {
            QsCommons.Logger.i("Test", "Color scheme successfully applied")
          } else {
            QsCommons.Logger.w("Test", "Colors still at defaults (scheme may not have applied yet)")
          }
        }
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Manual Testing:")
        QsCommons.Logger.i("Test", "  1. Colors should match 'Gruvbox' scheme (default)")
        QsCommons.Logger.i("Test", "  2. Toggle dark mode to see variant switch:")
        QsCommons.Logger.i("Test", "     QsCommons.Settings.data.colorSchemes.darkMode = false")
        QsCommons.Logger.i("Test", "  3. Apply different scheme:")
        QsCommons.Logger.i("Test", "     QsServices.ColorSchemeService.applyScheme('Tokyo Night')")
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "=== Test 11 Complete ===")
        QsCommons.Logger.i("Test", "")
        
        // Continue to WallpaperService test
        Qt.callLater(() => {
          test12WallpaperTimer.start()
        })
      }

      // ========================================
      // Test 12: WallpaperService
      // ========================================

      Timer {
        id: test12WallpaperTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: runTest12_WallpaperService()
      }

      function runTest12_WallpaperService() {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "Test 12: WallpaperService")
        QsCommons.Logger.i("Test", "================================")
        QsCommons.Logger.i("Test", "")
        
        // Service status
        QsCommons.Logger.i("Test", "Service Status:")
        QsCommons.Logger.i("Test", "  Initialized: " + QsServices.WallpaperService.isInitialized)
        QsCommons.Logger.i("Test", "  Scanning:    " + QsServices.WallpaperService.scanning)
        QsCommons.Logger.i("Test", "")
        
        // Settings
        QsCommons.Logger.i("Test", "Settings:")
        QsCommons.Logger.i("Test", "  Directory:                    " + QsCommons.Settings.data.wallpaper.directory)
        QsCommons.Logger.i("Test", "  Default Wallpaper:            " + QsCommons.Settings.data.wallpaper.defaultWallpaper)
        QsCommons.Logger.i("Test", "  Fill Mode:                    " + QsCommons.Settings.data.wallpaper.fillMode)
        QsCommons.Logger.i("Test", "  Multi-Monitor Directories:    " + QsCommons.Settings.data.wallpaper.enableMultiMonitorDirectories)
        QsCommons.Logger.i("Test", "  Random Enabled:               " + QsCommons.Settings.data.wallpaper.randomEnabled)
        QsCommons.Logger.i("Test", "  Random Interval (sec):        " + QsCommons.Settings.data.wallpaper.randomIntervalSec)
        QsCommons.Logger.i("Test", "")
        
        // Fill modes
        QsCommons.Logger.i("Test", "Fill Modes: " + QsServices.WallpaperService.fillModeModel.count)
        for (var i = 0; i < QsServices.WallpaperService.fillModeModel.count; i++) {
          const mode = QsServices.WallpaperService.fillModeModel.get(i)
          const current = (mode.key === QsCommons.Settings.data.wallpaper.fillMode) ? " (CURRENT)" : ""
          QsCommons.Logger.i("Test", "  [" + i + "] " + mode.name + " (" + mode.key + ") = uniform " + mode.uniform + current)
        }
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Current Fill Mode Uniform: " + QsServices.WallpaperService.getFillModeUniform())
        QsCommons.Logger.i("Test", "")
        
        // Per-screen wallpapers
        QsCommons.Logger.i("Test", "Screen Wallpapers:")
        for (var i = 0; i < Quickshell.screens.length; i++) {
          const screen = Quickshell.screens[i]
          const wallpaper = QsServices.WallpaperService.getWallpaper(screen.name)
          const directory = QsServices.WallpaperService.getMonitorDirectory(screen.name)
          const wallpaperList = QsServices.WallpaperService.getWallpapersList(screen.name)
          
          QsCommons.Logger.i("Test", "  [" + i + "] " + screen.name + ":")
          QsCommons.Logger.i("Test", "      Current:   " + wallpaper)
          QsCommons.Logger.i("Test", "      Directory: " + directory)
          QsCommons.Logger.i("Test", "      Available: " + wallpaperList.length + " wallpapers")
          
          if (wallpaperList.length > 0) {
            for (var j = 0; j < Math.min(3, wallpaperList.length); j++) {
              QsCommons.Logger.i("Test", "        - " + wallpaperList[j])
            }
            if (wallpaperList.length > 3) {
              QsCommons.Logger.i("Test", "        ... and " + (wallpaperList.length - 3) + " more")
            }
          }
        }
        QsCommons.Logger.i("Test", "")
        
        // Verify default wallpaper exists
        const defaultWallpaper = QsCommons.Settings.data.wallpaper.defaultWallpaper
        if (defaultWallpaper && defaultWallpaper !== "") {
          QsCommons.Logger.i("Test", "Default Wallpaper:")
          QsCommons.Logger.i("Test", "  Path: " + defaultWallpaper)
        }
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "Manual Testing:")
        QsCommons.Logger.i("Test", "  1. Add wallpapers to ~/Pictures/Wallpapers/")
        QsCommons.Logger.i("Test", "  2. Reload shell to detect new wallpapers")
        QsCommons.Logger.i("Test", "  3. Change wallpaper:")
        QsCommons.Logger.i("Test", "     QsServices.WallpaperService.changeWallpaper('/path/to/image.jpg')")
        QsCommons.Logger.i("Test", "  4. Enable random wallpapers:")
        QsCommons.Logger.i("Test", "     QsCommons.Settings.data.wallpaper.randomEnabled = true")
        QsCommons.Logger.i("Test", "  5. Test fill modes:")
        QsCommons.Logger.i("Test", "     QsCommons.Settings.data.wallpaper.fillMode = 'fit'")
        QsCommons.Logger.i("Test", "")
        
        QsCommons.Logger.i("Test", "=== Test 12 Complete ===")
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
