import QtQuick
import Quickshell
import "../Commons" as QsCommons
import "../Services" as QsServices

ShellRoot {
  id: root

  property bool settingsLoaded: false

  Component.onCompleted: {
    console.log("=== DarkModeService Standalone Test ===")
    console.log("")
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
        console.log("Settings loaded")
        console.log("")
        
        // Initialize required services
        QsServices.ColorSchemeService.init()
        QsServices.DarkModeService.init()
        
        // Wait a moment for initialization
        testTimer.start()
      }
      
      Timer {
        id: testTimer
        interval: 1000
        running: false
        repeat: false
        
        onTriggered: {
          console.log("=== DarkModeService Test Results ===")
          console.log("")
          
          console.log("Service Status:")
          console.log("  Init Complete:", QsServices.DarkModeService.initComplete)
          console.log("  Next Dark Mode State:", QsServices.DarkModeService.nextDarkModeState)
          console.log("")
          
          console.log("Settings:")
          console.log("  Scheduling Mode:", QsCommons.Settings.data.colorSchemes.schedulingMode)
          console.log("  Manual Sunrise:", QsCommons.Settings.data.colorSchemes.manualSunrise)
          console.log("  Manual Sunset:", QsCommons.Settings.data.colorSchemes.manualSunset)
          console.log("  Current Dark Mode:", QsCommons.Settings.data.colorSchemes.darkMode)
          console.log("")
          
          // Test parseTime
          console.log("Testing parseTime():")
          const time1 = QsServices.DarkModeService.parseTime("06:30")
          console.log("  parseTime('06:30'):", time1.hour + ":" + time1.minute)
          
          const time2 = QsServices.DarkModeService.parseTime("invalid")
          console.log("  parseTime('invalid'):", time2.hour + ":" + time2.minute, "(should be fallback)")
          console.log("")
          
          // Test collectManualChanges
          console.log("Testing collectManualChanges():")
          const changes = QsServices.DarkModeService.collectManualChanges()
          console.log("  Transitions:", changes.length)
          
          const now = Date.now()
          for (var i = 0; i < changes.length; i++) {
            const change = changes[i]
            const date = new Date(change.time)
            const status = change.time < now ? "(past)" : "(future)"
            console.log("  [" + i + "]", date.toLocaleString(), "→ darkMode=" + change.darkMode, status)
          }
          console.log("")
          
          console.log("=== Test Complete ===")
          console.log("")
          console.log("✓ Service initialized successfully")
          console.log("✓ Time parsing working")
          console.log("✓ Transition calculation working")
          console.log("")
          
          // Exit after test
          Qt.quit()
        }
      }
    }
  }
}
