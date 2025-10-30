import QtQuick
import Quickshell
import "../Commons" as QsCommons
import "../Services" as QsServices

ShellRoot {
  Component.onCompleted: {
    QsCommons.Logger.i("Test", "=================================")
    QsCommons.Logger.i("Test", "ProgramCheckerService Test Suite")
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
      QsCommons.Logger.i("Test", "=== Test Complete ===")
      QsCommons.Logger.i("Test", "")
      
      // Exit after test completes
      Qt.quit()
    }
  }
}
