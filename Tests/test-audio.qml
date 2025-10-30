import QtQuick
import Quickshell
import "../Commons" as QsCommons
import "../Services" as QsServices

ShellRoot {
  Timer {
    interval: 2000
    running: true
    onTriggered: {
      console.log("=== AudioService Test ===")
      console.log("")
      
      // Test device detection
      console.log("Sinks (Output Devices):", QsServices.AudioService.sinks.length)
      for (var i = 0; i < QsServices.AudioService.sinks.length; i++) {
        const sink = QsServices.AudioService.sinks[i]
        console.log(`  [${i}]`, sink.description || sink.name || "Unknown")
      }
      console.log("")
      
      console.log("Sources (Input Devices):", QsServices.AudioService.sources.length)
      for (var i = 0; i < QsServices.AudioService.sources.length; i++) {
        const source = QsServices.AudioService.sources[i]
        console.log(`  [${i}]`, source.description || source.name || "Unknown")
      }
      console.log("")
      
      // Test current output device
      console.log("Current Output:")
      if (QsServices.AudioService.sink) {
        console.log("  Device:", QsServices.AudioService.sink.description || 
                                   QsServices.AudioService.sink.name || "None")
        console.log("  Volume:", (QsServices.AudioService.volume * 100).toFixed(0) + "%")
        console.log("  Muted:", QsServices.AudioService.muted)
      } else {
        console.log("  No output device")
      }
      console.log("")
      
      // Test current input device
      console.log("Current Input:")
      if (QsServices.AudioService.source) {
        console.log("  Device:", QsServices.AudioService.source.description || 
                                   QsServices.AudioService.source.name || "None")
        console.log("  Volume:", (QsServices.AudioService.inputVolume * 100).toFixed(0) + "%")
        console.log("  Muted:", QsServices.AudioService.inputMuted)
      } else {
        console.log("  No input device")
      }
      console.log("")
      
      // Test volume control
      console.log("Testing volume control...")
      const originalVolume = QsServices.AudioService.volume
      console.log("  Current:", (originalVolume * 100).toFixed(0) + "%")
      
      QsServices.AudioService.increaseVolume()
      Qt.callLater(() => {
        console.log("  After increase:", (QsServices.AudioService.volume * 100).toFixed(0) + "%")
        
        QsServices.AudioService.decreaseVolume()
        Qt.callLater(() => {
          console.log("  After decrease:", (QsServices.AudioService.volume * 100).toFixed(0) + "%")
          console.log("")
          
          // Test mute toggle
          console.log("Testing mute toggle...")
          const originalMuted = QsServices.AudioService.muted
          console.log("  Current mute state:", originalMuted)
          
          QsServices.AudioService.setOutputMuted(!originalMuted)
          Qt.callLater(() => {
            console.log("  After toggle:", QsServices.AudioService.muted)
            
            // Restore original state
            QsServices.AudioService.setOutputMuted(originalMuted)
            console.log("  Restored to:", QsServices.AudioService.muted)
            console.log("")
            console.log("Test complete.")
            Qt.quit()
          })
        })
      })
    }
  }
}
