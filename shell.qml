import QtQuick
import Quickshell
import "Commons" as QsCommons
import "Services" as QsServices

ShellRoot {
  id: shellRoot

  property bool settingsLoaded: false

  Component.onCompleted: {
    QsCommons.Logger.i("Shell", "---------------------------")
    QsCommons.Logger.i("Shell", "YAQS Shell Loading...")
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
        QsCommons.Logger.i("Shell", "---------------------------")
        QsCommons.Logger.i("Shell", "YAQS Hello!")
        QsCommons.Logger.i("Shell", "---------------------------")
        
        // Start programservice tests
        testProgramChecker()
      }

      Connections {
        target: QsServices.ProgramCheckerService
        function onChecksCompleted() {
          QsCommons.Logger.i("Shell", "")
          QsCommons.Logger.i("Shell", "=== ProgramCheckerService Results ===")
          QsCommons.Logger.i("Shell", "")
          QsCommons.Logger.i("Shell", "Program Availability:")
          QsCommons.Logger.i("Shell", "  matugen: " + QsServices.ProgramCheckerService.matugenAvailable)
          QsCommons.Logger.i("Shell", "  kitty: " + QsServices.ProgramCheckerService.kittyAvailable)
          QsCommons.Logger.i("Shell", "  foot: " + QsServices.ProgramCheckerService.footAvailable)
          QsCommons.Logger.i("Shell", "  ghostty: " + QsServices.ProgramCheckerService.ghosttyAvailable)
          QsCommons.Logger.i("Shell", "  gpu-screen-recorder: " + QsServices.ProgramCheckerService.gpuScreenRecorderAvailable)
          QsCommons.Logger.i("Shell", "  nmcli: " + QsServices.ProgramCheckerService.nmcliAvailable)
          QsCommons.Logger.i("Shell", "  bluetoothctl: " + QsServices.ProgramCheckerService.bluetoothctlAvailable)
          QsCommons.Logger.i("Shell", "  brightnessctl: " + QsServices.ProgramCheckerService.brightnessctlAvailable)
          QsCommons.Logger.i("Shell", "  playerctl: " + QsServices.ProgramCheckerService.playerctlAvailable)
          QsCommons.Logger.i("Shell", "")
          QsCommons.Logger.i("Shell", "=== Test Complete ===")
          QsCommons.Logger.i("Shell", "")
          
          // Test compositor service next
          Qt.callLater(() => {
            testCompositorService()
            // Wait for backend initialization before testing data
            testDataTimer.start()
          })
        }
      }

      function testProgramChecker() {
        QsCommons.Logger.i("Shell", "")
        QsCommons.Logger.i("Shell", "=== ProgramCheckerService Test ===")
        QsCommons.Logger.i("Shell", "Checking for required programs...")
        QsCommons.Logger.i("Shell", "(Results will appear when checks complete)")
        QsCommons.Logger.i("Shell", "")
      }

      Timer {
        id: testDataTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: testCompositorData()
      }

      Connections {
        target: QsServices.CompositorService
        function onWorkspaceChanged() {
          QsCommons.Logger.d("Shell", "Workspace changed event received")
        }
        function onActiveWindowChanged() {
          QsCommons.Logger.d("Shell", "Active window changed event received")
        }
        function onDisplayScalesChanged() {
          QsCommons.Logger.i("Shell", "Display scales updated")
        }
      }

      // Compositor test
      function testCompositorService() {
        QsCommons.Logger.i("Shell", "")
        QsCommons.Logger.i("Shell", "=== CompositorService Detection Test ===")
        QsCommons.Logger.i("Shell", "")
        
        QsCommons.Logger.i("Shell", "Environment Variables:")
        QsCommons.Logger.i("Shell", "  HYPRLAND_INSTANCE_SIGNATURE: " + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
        QsCommons.Logger.i("Shell", "  NIRI_SOCKET: " + Quickshell.env("NIRI_SOCKET"))
        QsCommons.Logger.i("Shell", "  SWAYSOCK: " + Quickshell.env("SWAYSOCK"))
        QsCommons.Logger.i("Shell", "")
        
        QsCommons.Logger.i("Shell", "Detected Compositor:")
        QsCommons.Logger.i("Shell", "  isHyprland: " + QsServices.CompositorService.isHyprland)
        QsCommons.Logger.i("Shell", "  isNiri: " + QsServices.CompositorService.isNiri)
        QsCommons.Logger.i("Shell", "  isSway: " + QsServices.CompositorService.isSway)
        QsCommons.Logger.i("Shell", "")
        
        QsCommons.Logger.i("Shell", "Backend loaded: " + (QsServices.CompositorService.backend !== null))
        QsCommons.Logger.i("Shell", "Display cache path: " + QsServices.CompositorService.displayCachePath)
        QsCommons.Logger.i("Shell", "")
        
        QsCommons.Logger.i("Shell", "=== Test Complete ===")
        QsCommons.Logger.i("Shell", "")
      }

      // Hyprland support test
      function testCompositorData() {
        QsCommons.Logger.i("Shell", "")
        QsCommons.Logger.i("Shell", "=== HyprlandService Data Test ===")
        QsCommons.Logger.i("Shell", "")
        
        // Test workspace data
        QsCommons.Logger.i("Shell", "Workspaces (count: " + QsServices.CompositorService.workspaces.count + "):")
        for (var i = 0; i < QsServices.CompositorService.workspaces.count; i++) {
          const ws = QsServices.CompositorService.workspaces.get(i)
          QsCommons.Logger.i("Shell", "  [" + ws.id + "] " + ws.name + ": " +
            "focused=" + ws.isFocused + ", " +
            "active=" + ws.isActive + ", " +
            "occupied=" + ws.isOccupied + ", " +
            "output=" + ws.output)
        }
        QsCommons.Logger.i("Shell", "")
        
        // Test window data
        QsCommons.Logger.i("Shell", "Windows (count: " + QsServices.CompositorService.windows.count + "):")
        for (var i = 0; i < Math.min(QsServices.CompositorService.windows.count, 5); i++) {
          const win = QsServices.CompositorService.windows.get(i)
          QsCommons.Logger.i("Shell", "  [" + win.id.substring(0, 8) + "...] " +
            "title=\"" + win.title + "\", " +
            "app=\"" + win.appId + "\", " +
            "ws=" + win.workspaceId + ", " +
            "focused=" + win.isFocused)
        }
        if (QsServices.CompositorService.windows.count > 5) {
          QsCommons.Logger.i("Shell", "  ... and " + (QsServices.CompositorService.windows.count - 5) + " more")
        }
        QsCommons.Logger.i("Shell", "")
        
        // Test focused window
        const focused = QsServices.CompositorService.getFocusedWindow()
        if (focused) {
          QsCommons.Logger.i("Shell", "Focused Window:")
          QsCommons.Logger.i("Shell", "  title: \"" + focused.title + "\"")
          QsCommons.Logger.i("Shell", "  app: \"" + focused.appId + "\"")
          QsCommons.Logger.i("Shell", "  workspace: " + focused.workspaceId)
        } else {
          QsCommons.Logger.i("Shell", "No focused window")
        }
        QsCommons.Logger.i("Shell", "")
        
        // Test current workspace
        const currentWs = QsServices.CompositorService.getCurrentWorkspace()
        if (currentWs) {
          QsCommons.Logger.i("Shell", "Current Workspace:")
          QsCommons.Logger.i("Shell", "  id: " + currentWs.id)
          QsCommons.Logger.i("Shell", "  name: " + currentWs.name)
          QsCommons.Logger.i("Shell", "  output: " + currentWs.output)
        }
        QsCommons.Logger.i("Shell", "")
        
        // Trigger display scale query
        QsCommons.Logger.i("Shell", "Querying display scales...")
        QsServices.CompositorService.updateDisplayScales()
        
        // Wait a bit then show display scales
        displayScaleTimer.start()
      }

      Timer {
        id: displayScaleTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
          QsCommons.Logger.i("Shell", "")
          QsCommons.Logger.i("Shell", "Display Scales:")
          const scales = QsServices.CompositorService.displayScales
          const displayNames = Object.keys(scales)
          
          if (displayNames.length === 0) {
            QsCommons.Logger.i("Shell", "  No displays detected yet")
          } else {
            for (var i = 0; i < displayNames.length; i++) {
              const name = displayNames[i]
              const info = scales[name]
              QsCommons.Logger.i("Shell", "  " + name + ":")
              QsCommons.Logger.i("Shell", "    resolution: " + info.width + "x" + info.height)
              QsCommons.Logger.i("Shell", "    scale: " + info.scale)
              QsCommons.Logger.i("Shell", "    refresh: " + info.refresh_rate + " Hz")
              QsCommons.Logger.i("Shell", "    position: (" + info.x + ", " + info.y + ")")
              QsCommons.Logger.i("Shell", "    vrr: " + info.vrr)
              QsCommons.Logger.i("Shell", "    focused: " + info.focused)
            }
          }
          QsCommons.Logger.i("Shell", "")
          QsCommons.Logger.i("Shell", "Cache file: " + QsServices.CompositorService.displayCachePath)
          QsCommons.Logger.i("Shell", "")
          QsCommons.Logger.i("Shell", "")
        }
      }
    }
  }
}
