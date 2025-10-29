import QtQuick
import Quickshell
import "Commons" as QsCommons
import "Services" as QsServices

ShellRoot {
  Connections {
    target: QsCommons.Settings
    function onSettingsLoaded() {
      console.log("=== ProgramCheckerService Test ===")
      console.log("")
      
      // Wait for checks to complete
      QsServices.ProgramCheckerService.checksCompleted.connect(() => {
        console.log("All checks completed!")
        console.log("")
        console.log("Results:")
        console.log("  matugen:", QsServices.ProgramCheckerService.matugenAvailable)
        console.log("  kitty:", QsServices.ProgramCheckerService.kittyAvailable)
        console.log("  foot:", QsServices.ProgramCheckerService.footAvailable)
        console.log("  ghostty:", QsServices.ProgramCheckerService.ghosttyAvailable)
        console.log("  gpu-screen-recorder:", QsServices.ProgramCheckerService.gpuScreenRecorderAvailable)
        console.log("  nmcli:", QsServices.ProgramCheckerService.nmcliAvailable)
        console.log("  bluetoothctl:", QsServices.ProgramCheckerService.bluetoothctlAvailable)
        console.log("  brightnessctl:", QsServices.ProgramCheckerService.brightnessctlAvailable)
        console.log("  playerctl:", QsServices.ProgramCheckerService.playerctlAvailable)
        console.log("")
        console.log("Test complete. Exiting in 1 second...")
        
        exitTimer.start()
      })
    }
  }
  
  Timer {
    id: exitTimer
    interval: 1000
    onTriggered: Qt.quit()
  }
}
