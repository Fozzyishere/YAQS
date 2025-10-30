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
        
        // All tests complete
        QsCommons.Logger.i("Shell", "")
        QsCommons.Logger.i("Shell", "========================================")
        QsCommons.Logger.i("Shell", "All Tests Complete")
        QsCommons.Logger.i("Shell", "========================================")
        QsCommons.Logger.i("Shell", "")
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
    }
  }
}
