import QtQuick
import Quickshell
import "../Commons" as QsCommons
import "../Services" as QsServices

ShellRoot {
  Component.onCompleted: {
    QsCommons.Logger.i("Test", "============================")
    QsCommons.Logger.i("Test", "CompositorService Test Suite")
    QsCommons.Logger.i("Test", "============================")
    QsCommons.Logger.i("Test", "")
    
    // Run detection test
    testCompositorDetection()
    
    // Wait for backend initialization before testing data
    testDataTimer.start()
  }

  Timer {
    id: testDataTimer
    interval: 2000
    running: false
    repeat: false
    onTriggered: {
      testCompositorData()
      // Wait for display scale query
      displayScaleTimer.start()
    }
  }

  Timer {
    id: displayScaleTimer
    interval: 1000
    running: false
    repeat: false
    onTriggered: {
      testDisplayScales()
      // Exit after all tests complete
      Qt.callLater(() => {
        QsCommons.Logger.i("Test", "")
        QsCommons.Logger.i("Test", "=== All Tests Complete ===")
        QsCommons.Logger.i("Test", "")
        Qt.quit()
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
      QsCommons.Logger.i("Test", "Display scales updated")
    }
  }

  // Test 1: Compositor Detection
  function testCompositorDetection() {
    QsCommons.Logger.i("Test", "=== Test 1: Compositor Detection ===")
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

  // Test 2: Workspace and Window Data
  function testCompositorData() {
    QsCommons.Logger.i("Test", "=== Test 2: Workspace & Window Data ===")
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

  // Test 3: Display Scales
  function testDisplayScales() {
    QsCommons.Logger.i("Test", "")
    QsCommons.Logger.i("Test", "=== Test 3: Display Scales ===")
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
  }
}
